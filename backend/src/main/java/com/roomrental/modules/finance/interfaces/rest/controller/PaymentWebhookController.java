package com.roomrental.modules.finance.interfaces.rest.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.finance.application.dto.PaymentWebhookCommand;
import com.roomrental.modules.finance.application.dto.TransactionResult;
import com.roomrental.modules.finance.application.service.PaymentService;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import com.roomrental.modules.finance.interfaces.rest.dto.SePayWebhookRequest;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/v1/payments")
@Tag(name = "Finance - Webhook", description = "Public webhook endpoint for automated payments reconciliation")
public class PaymentWebhookController {

    private static final Logger log = LoggerFactory.getLogger(PaymentWebhookController.class);

    private final PaymentService paymentService;
    private final InvoiceRepository invoiceRepository;
    private final RoomRepository roomRepository;
    private final MotelRepository motelRepository;
    
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${app.sepay.apikey:}")
    private String sepayApiKey;

    public PaymentWebhookController(
            PaymentService paymentService,
            InvoiceRepository invoiceRepository,
            RoomRepository roomRepository,
            MotelRepository motelRepository) {
        this.paymentService = paymentService;
        this.invoiceRepository = invoiceRepository;
        this.roomRepository = roomRepository;
        this.motelRepository = motelRepository;
    }

    @PostMapping("/webhook")
    @Operation(summary = "Hứng Webhook từ SePay.vn khi có biến động số dư (Không cần JWT)")
    public ResponseEntity<TransactionResult> receiveWebhook(
            @RequestHeader(value = "X-SePay-Signature", required = false) String signatureHeader,
            @RequestBody String rawBody) {

        log.info("Received SePay webhook signature: {}, body: {}", signatureHeader, rawBody);

        SePayWebhookRequest request;
        try {
            request = objectMapper.readValue(rawBody, SePayWebhookRequest.class);
        } catch (Exception e) {
            log.error("Failed to parse raw body to SePayWebhookRequest", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }

        // Parse transfer description: SePay code has priority, fallback to content
        String memo = request.code() != null && !request.code().isBlank() ? request.code() : request.content();
        Long invoiceId = parseInvoiceIdFromMemo(memo);

        // Fetch motel-specific webhook secret key if invoiceId is resolved
        String requiredSecret = getSecretKeyForInvoice(invoiceId);

        if (requiredSecret != null && !requiredSecret.isBlank()) {
            // Verify HMAC-SHA256 signature using the motel-specific secret key
            if (signatureHeader == null || signatureHeader.isBlank()) {
                log.warn("Unauthorized webhook call: Missing X-SePay-Signature header for Invoice ID: {}", invoiceId);
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }

            String receivedHash = signatureHeader.trim();
            if (receivedHash.startsWith("sha256=")) {
                receivedHash = receivedHash.substring(7);
            }

            try {
                Mac mac = Mac.getInstance("HmacSHA256");
                SecretKeySpec secretKeySpec = new SecretKeySpec(requiredSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
                mac.init(secretKeySpec);
                byte[] rawHmac = mac.doFinal(rawBody.getBytes(StandardCharsets.UTF_8));

                StringBuilder sb = new StringBuilder();
                for (byte b : rawHmac) {
                    sb.append(String.format("%02x", b));
                }
                String expectedHash = sb.toString();

                if (!MessageDigest.isEqual(receivedHash.getBytes(StandardCharsets.UTF_8), expectedHash.getBytes(StandardCharsets.UTF_8))) {
                    log.warn("Unauthorized webhook call: Signature mismatch for Invoice ID: {}", invoiceId);
                    return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
                }
            } catch (Exception e) {
                log.error("Error verifying signature for Invoice ID: {}", invoiceId, e);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }
        } else {
            // Fallback to global SePay API Key (no signature verification, fallback to legacy key verification)
            if (sepayApiKey != null && !sepayApiKey.isBlank()) {
                log.warn("No motel-specific secret key found for Invoice ID: {}. Rejecting unauthenticated webhook.", invoiceId);
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            } else {
                // Local dev mode fallback: no security keys configured
                log.info("No SePay key configured on motel bank_config or globally. Allowing webhook call for local debugging.");
            }
        }

        String transactionRef = request.referenceCode() != null && !request.referenceCode().isBlank()
                ? request.referenceCode() : "SEPAY-" + request.id();

        PaymentWebhookCommand command = new PaymentWebhookCommand(
                transactionRef,
                request.transferAmount(),
                request.gateway(),
                memo,
                rawBody
        );

        TransactionResult result = paymentService.processWebhook(command);
        return ResponseEntity.ok(result);
    }

    private Long parseInvoiceIdFromMemo(String memo) {
        if (memo == null || memo.isBlank()) return null;
        try {
            String upper = memo.toUpperCase().trim();
            // Match pattern like INV-88, PT88, INV88, PT-88, SEVQR PT88, etc.
            Pattern pattern = Pattern.compile("(?:INV|PT)-?(\\d+)");
            Matcher matcher = pattern.matcher(upper);
            if (matcher.find()) {
                return Long.parseLong(matcher.group(1));
            }
            // Fallback: search for any sequence of digits if there's no prefix
            Pattern fallbackPattern = Pattern.compile("(\\d+)");
            Matcher fallbackMatcher = fallbackPattern.matcher(upper);
            if (fallbackMatcher.find()) {
                return Long.parseLong(fallbackMatcher.group(1));
            }
        } catch (Exception e) {
            log.error("Failed to parse invoice ID from memo: " + memo, e);
        }
        return null;
    }

    private String getSecretKeyForInvoice(Long invoiceId) {
        if (invoiceId == null) return null;
        try {
            // Bypass tenant filter to resolve tenant ID natively
            UUID tenantId = invoiceRepository.findTenantIdByInvoiceIdNative(invoiceId).orElse(null);
            if (tenantId == null) return null;

            String previousTenantId = TenantContext.getCurrentTenantId();
            try {
                // Securely bind context to this tenant
                TenantContext.setCurrentTenantId(tenantId.toString());

                Invoice invoice = invoiceRepository.findById(invoiceId).orElse(null);
                if (invoice == null) return null;

                Room room = roomRepository.findById(invoice.getRoomId()).orElse(null);
                if (room == null) return null;

                Motel motel = motelRepository.findByIdAndTenantId(room.getMotelId(), tenantId).orElse(null);
                if (motel == null || motel.getBankConfig() == null || motel.getBankConfig().isBlank()) return null;

                JsonNode node = objectMapper.readTree(motel.getBankConfig());
                if (node.has("secretKey")) {
                    return node.get("secretKey").asText();
                }
            } finally {
                // Restore tenant context
                if (previousTenantId != null) {
                    TenantContext.setCurrentTenantId(previousTenantId);
                } else {
                    TenantContext.clear();
                }
            }
        } catch (Exception e) {
            log.error("Failed to retrieve webhook secret key for Invoice ID: {}", invoiceId, e);
        }
        return null;
    }
}

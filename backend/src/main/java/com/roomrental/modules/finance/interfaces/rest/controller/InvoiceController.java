package com.roomrental.modules.finance.interfaces.rest.controller;

import com.roomrental.modules.finance.application.dto.*;
import com.roomrental.modules.finance.application.service.InvoiceService;
import com.roomrental.modules.finance.interfaces.rest.dto.InvoiceAdjustRequest;
import com.roomrental.modules.finance.interfaces.rest.dto.InvoiceGenerateRequest;
import com.roomrental.modules.finance.interfaces.rest.dto.PaymentConfigRegisterRequest;
import com.roomrental.modules.finance.interfaces.rest.dto.InvoicePaymentInfoResult;
import com.roomrental.modules.finance.application.service.SePayIntegrationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;


@RestController
@RequestMapping("/api/v1/invoices")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Finance - Invoices", description = "UC73, UC74, UC75, UC76, UC77")
public class InvoiceController {

    private final InvoiceService service;
    private final SePayIntegrationService sePayIntegrationService;

    public InvoiceController(InvoiceService service, SePayIntegrationService sePayIntegrationService) {
        this.service = service;
        this.sePayIntegrationService = sePayIntegrationService;
    }

    @PostMapping("/payment-config/{motelId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Configure SePay payment for a motel")
    public ResponseEntity<Void> activateAutomaticPayment(
            @PathVariable Long motelId,
            @RequestBody @Valid PaymentConfigRegisterRequest request) {
        sePayIntegrationService.activateAutomaticPayment(
                motelId,
                request.sePayApiKey(),
                request.accountNumber(),
                request.bankName()
        );
        return ResponseEntity.ok().build();
    }

    @PostMapping("/generate")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Generate invoices for a motel (UC73)")
    public ResponseEntity<Void> generateForMotel(@RequestBody @Valid InvoiceGenerateRequest request) {
        service.generateForMotel(new InvoiceGenerateCommand(request.motelId(), request.billingMonth()));
        return ResponseEntity.accepted().build();
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "List invoices (UC74)")
    public ResponseEntity<Page<InvoiceResult>> list(
            @RequestParam(required = false) Long motelId,
            @RequestParam(required = false) String status,
            Pageable pageable) {
        return ResponseEntity.ok(service.list(motelId, status, pageable));
    }


    @GetMapping("/me")
    @PreAuthorize("hasAnyRole('RESIDENT')")
    @Operation(summary = "List my invoices (UC74 - Tenant)")
    public ResponseEntity<Page<InvoiceResult>> getMyInvoices(@RequestParam(required = false) String status, Pageable pageable) {
        return ResponseEntity.ok(service.listMyInvoices(status, pageable));
    }

    @GetMapping("/my-balance")
    @PreAuthorize("hasAnyRole('RESIDENT')")
    @Operation(summary = "Get my current balance (Tenant)")
    public ResponseEntity<java.math.BigDecimal> getMyBalance() {
        return ResponseEntity.ok(service.getMyBalance());
    }

    @GetMapping("/balance/{residentId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Get resident's balance (Manager)")
    public ResponseEntity<java.math.BigDecimal> getResidentBalance(@PathVariable UUID residentId) {
        return ResponseEntity.ok(service.getResidentBalance(residentId));
    }

    @GetMapping("/balances")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Get multiple residents' current balances (Manager)")
    public ResponseEntity<java.util.Map<UUID, java.math.BigDecimal>> getResidentBalances(@RequestParam java.util.List<UUID> residentIds) {
        return ResponseEntity.ok(service.getResidentBalances(residentIds));
    }



    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Get invoice details (UC75)")
    public ResponseEntity<InvoiceResult> getDetail(@PathVariable Long id) {
        return ResponseEntity.ok(service.getDetail(id));
    }

    @GetMapping("/{id}/payment-info")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Get VietQR payment info and dynamic QR code (UC78)")
    public ResponseEntity<InvoicePaymentInfoResult> getPaymentInfo(@PathVariable Long id) {
        return ResponseEntity.ok(service.getPaymentInfo(id));
    }

    @PostMapping("/{id}/adjust")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Adjust/Void an invoice (UC76)")
    public ResponseEntity<InvoiceResult> adjustInvoice(@PathVariable Long id,
            @RequestBody @Valid InvoiceAdjustRequest request) {
        InvoiceAdjustCommand cmd = new InvoiceAdjustCommand(
                id, request.reason(), request.correctedReadings(),
                request.customAdjustments());
        return ResponseEntity.ok(service.adjustInvoice(cmd));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Soft delete an invoice (UC77)")
    public ResponseEntity<Void> deleteInvoice(@PathVariable Long id) {
        service.deleteInvoice(id);
        return ResponseEntity.noContent().build();
    }
}

package com.roomrental.modules.finance.application.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.security.AesCryptoConverter;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.security.SecureRandom;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class SePayIntegrationService {

    private static final Logger log = LoggerFactory.getLogger(SePayIntegrationService.class);

    private final MotelRepository motelRepository;
    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate;
    
    // Concurrency lock map per motelId
    private final ConcurrentHashMap<Long, Boolean> activeLocks = new ConcurrentHashMap<>();
    private final AesCryptoConverter cryptoConverter = new AesCryptoConverter();

    @Value("${app.sepay.webhook-url:https://your-domain.com/api/v1/payments/webhook}")
    private String sepayWebhookUrl;

    @Value("${app.sepay.api-url:https://my.sepay.vn/api/v1/webhooks}")
    private String sepayApiUrl;

    public SePayIntegrationService(MotelRepository motelRepository, ObjectMapper objectMapper) {
        this.motelRepository = motelRepository;
        this.objectMapper = objectMapper;
        this.restTemplate = new RestTemplate();
    }

    @Transactional(rollbackFor = Exception.class)
    public void activateAutomaticPayment(Long motelId, String sePayApiKey, String accountNumber, String bankName) {
        UUID tenantId = SecurityUtils.requireTenantId();
        
        // Concurrency Lock Check
        if (activeLocks.putIfAbsent(motelId, Boolean.TRUE) != null) {
            throw BaseException.badRequest("Yêu cầu cấu hình thanh toán cho khu trọ này đang được xử lý. Vui lòng không bấm liên tục.");
        }

        try {
            Motel motel = motelRepository.findByIdAndTenantId(motelId, tenantId)
                    .orElseThrow(() -> BaseException.notFound("Motel", motelId));

            String existingConfig = motel.getBankConfig();
            String actualEncryptedApiKey;
            String existingWebhookId = null;

            // Check if user is updating with a masked API Key (e.g. ••••••••)
            if (sePayApiKey == null || sePayApiKey.isBlank() || sePayApiKey.contains("•") || sePayApiKey.contains("*")) {
                if (existingConfig == null || existingConfig.isBlank()) {
                    throw BaseException.badRequest("API Key của SePay là bắt buộc cho lần cấu hình đầu tiên");
                }
                try {
                    JsonNode node = objectMapper.readTree(existingConfig);
                    if (node.has("sePayApiKey")) {
                        actualEncryptedApiKey = node.get("sePayApiKey").asText();
                    } else {
                        throw BaseException.badRequest("Không tìm thấy API Key cũ. Vui lòng nhập đầy đủ API Key.");
                    }
                } catch (Exception e) {
                    throw BaseException.badRequest("Cấu hình hiện tại bị lỗi. Vui lòng nhập lại API Key.");
                }
            } else {
                // Encrypt the brand new API Key
                actualEncryptedApiKey = cryptoConverter.convertToDatabaseColumn(sePayApiKey.trim());
            }

            // Extract existing webhook ID if present
            if (existingConfig != null && !existingConfig.isBlank()) {
                try {
                    JsonNode node = objectMapper.readTree(existingConfig);
                    if (node.has("webhookId")) {
                        existingWebhookId = node.get("webhookId").asText();
                    }
                } catch (Exception ignored) {}
            }

            // Decrypt API key to make calls to SePay
            String decryptedApiKey = cryptoConverter.convertToEntityAttribute(actualEncryptedApiKey);

            // Generate brand new secret key for this update cycle
            String secretKey = generateSecureRandomSecret();

            // Register or Update webhook on SePay
            String webhookId = saveOrUpdateWebhookOnSePay(decryptedApiKey, secretKey, existingWebhookId);

            // Fetch the Account Holder Name from SePay API
            String accountHolder = fetchAccountHolderName(decryptedApiKey, accountNumber);

            // Derive bankId (BIN) from bankName
            String bankId = deriveBankId(bankName);

            // Construct new bank_config JSON
            Map<String, String> configMap = new HashMap<>();
            configMap.put("bankId", bankId);
            configMap.put("bankAccount", accountNumber.trim());
            configMap.put("accountHolder", accountHolder);
            configMap.put("bankName", bankName);
            configMap.put("sePayApiKey", actualEncryptedApiKey);
            configMap.put("secretKey", secretKey);
            configMap.put("webhookId", webhookId);

            String jsonConfig = objectMapper.writeValueAsString(configMap);
            motel.setBankConfig(jsonConfig);
            motelRepository.save(motel);

            log.info("Successfully activated automatic payment for motelId={}, tenantId={}, webhookId={}",
                    motelId, tenantId, webhookId);

        } catch (BaseException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to process payment activation for motelId={}", motelId, e);
            throw new BaseException(org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR", "Đã xảy ra lỗi hệ thống khi liên kết SePay: " + e.getMessage());
        } finally {
            activeLocks.remove(motelId);
        }
    }

    private String saveOrUpdateWebhookOnSePay(String sePayApiKey, String secretKey, String existingWebhookId) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + sePayApiKey);

            boolean isBankHub = sepayApiUrl.contains("bankhub");
            Map<String, Object> payload = new HashMap<>();
            
            String targetUrl;
            HttpMethod method;

            if (isBankHub) {
                // Bank Hub API (upsert pattern)
                targetUrl = sepayApiUrl;
                method = HttpMethod.POST;
                payload.put("webhook_url", sepayWebhookUrl);
                payload.put("auth_type", "SECRET_KEY");
                payload.put("secret_key", secretKey);
                payload.put("active", 1);
                payload.put("allow_events", List.of("*"));
                log.info("Calling SePay Bank Hub Webhook upsert at: {}", targetUrl);
            } else {
                // Standard SePay API
                payload.put("secret_key", secretKey);
                payload.put("api_key", secretKey);
                
                if (sepayApiUrl.contains("/webhooks") && !sepayApiUrl.endsWith("/create")) {
                    // Official standard SePay API: https://my.sepay.vn/api/v1/webhooks
                    payload.put("webhook_url", sepayWebhookUrl);
                    payload.put("authen_type", "Api_Key");
                    payload.put("active", 1);
                    payload.put("event_type", "In_only");
                    payload.put("request_content_type", "Json");
                    
                    if (existingWebhookId != null && !existingWebhookId.isBlank()) {
                        targetUrl = sepayApiUrl + "/" + existingWebhookId;
                        method = HttpMethod.PATCH;
                        log.info("Updating standard SePay webhook ID: {} at URL: {}", existingWebhookId, targetUrl);
                    } else {
                        targetUrl = sepayApiUrl;
                        method = HttpMethod.POST;
                        log.info("Creating standard SePay webhook at URL: {}", targetUrl);
                    }
                } else {
                    // Custom SePay dashboard API: https://my.sepay.vn/web/api/v1/webhooks/create
                    payload.put("url", sepayWebhookUrl);
                    payload.put("gateway", "All");
                    payload.put("events", List.of("credit"));
                    
                    if (existingWebhookId != null && !existingWebhookId.isBlank()) {
                        method = HttpMethod.POST;
                        if (sepayApiUrl.endsWith("/create")) {
                            targetUrl = sepayApiUrl.substring(0, sepayApiUrl.length() - 7) + "/update/" + existingWebhookId;
                        } else {
                            targetUrl = sepayApiUrl + "/update/" + existingWebhookId;
                        }
                        log.info("Updating SePay dashboard webhook ID: {} at URL: {}", existingWebhookId, targetUrl);
                    } else {
                        method = HttpMethod.POST;
                        targetUrl = sepayApiUrl;
                        log.info("Creating SePay dashboard webhook at URL: {}", targetUrl);
                    }
                }
            }

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(payload, headers);
            ResponseEntity<Map> response = restTemplate.exchange(targetUrl, method, requestEntity, Map.class);

            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                log.error("SePay webhook registration failed. Status: {}, Body: {}", response.getStatusCode(), response.getBody());
                throw BaseException.badRequest("Không thể đăng ký Webhook với SePay. Vui lòng kiểm tra lại API Key.");
            }

            Map<String, Object> body = response.getBody();
            log.info("SePay Webhook response: {}", body);
            
            // Extract Webhook ID from response
            String idStr = null;
            if (body.containsKey("data")) {
                Object dataObj = body.get("data");
                if (dataObj instanceof Map) {
                    Map<?, ?> dataMap = (Map<?, ?>) dataObj;
                    if (dataMap.containsKey("id")) {
                        idStr = String.valueOf(dataMap.get("id"));
                    }
                }
            }
            if (idStr == null && body.containsKey("webhook")) {
                Object webhookObj = body.get("webhook");
                if (webhookObj instanceof Map) {
                    Map<?, ?> webMap = (Map<?, ?>) webhookObj;
                    if (webMap.containsKey("id")) {
                        idStr = String.valueOf(webMap.get("id"));
                    }
                }
            }
            if (idStr == null && body.containsKey("id")) {
                idStr = String.valueOf(body.get("id"));
            }
            if (idStr == null && body.containsKey("webhook_id")) {
                idStr = String.valueOf(body.get("webhook_id"));
            }
            
            if (idStr == null) {
                if (existingWebhookId != null) {
                    idStr = existingWebhookId;
                } else {
                    idStr = "sepay_webhook_active";
                }
            }

            return idStr;

        } catch (BaseException e) {
            throw e;
        } catch (Exception e) {
            log.error("Error communicating with SePay webhook API: ", e);
            throw BaseException.badRequest("Lỗi kết nối với SePay: " + e.getMessage());
        }
    }

    private String fetchAccountHolderName(String sePayApiKey, String accountNumber) {
        String defaultName = "CHỦ TRỌ";
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + sePayApiKey);
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<Map> response = restTemplate.exchange(
                    "https://my.sepay.vn/userapi/bankaccounts/list",
                    HttpMethod.GET,
                    entity,
                    Map.class
            );

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                List<Map<String, Object>> accounts = (List<Map<String, Object>>) response.getBody().get("bankaccounts");
                if (accounts != null) {
                    String cleanTarget = accountNumber.replaceAll("\\s+", "");
                    for (Map<String, Object> acc : accounts) {
                        String accNum = (String) acc.get("account_number");
                        if (accNum != null && accNum.replaceAll("\\s+", "").equals(cleanTarget)) {
                            String holder = (String) acc.get("account_holder_name");
                            if (holder != null && !holder.isBlank()) {
                                return holder.toUpperCase();
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Failed to fetch bank account list from SePay, using default name: {}", e.getMessage());
        }
        return defaultName;
    }

    private String deriveBankId(String bankName) {
        if (bankName == null) return "";
        String upper = bankName.toUpperCase();
        if (upper.contains("VIETCOMBANK") || upper.contains("VCB")) return "VCB";
        if (upper.contains("VIETINBANK") || upper.contains("ICB") || upper.contains("VIETIN")) return "ICB";
        if (upper.contains("TECHCOMBANK") || upper.contains("TCB")) return "TCB";
        if (upper.contains("MBBANK") || upper.contains("MB") || upper.contains("QUÂN ĐỘI")) return "MB";
        if (upper.contains("BIDV")) return "BIDV";
        if (upper.contains("ACB")) return "ACB";
        if (upper.contains("VIB")) return "VIB";
        return bankName;
    }

    private String generateSecureRandomSecret() {
        byte[] randomBytes = new byte[24];
        new SecureRandom().nextBytes(randomBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }
}

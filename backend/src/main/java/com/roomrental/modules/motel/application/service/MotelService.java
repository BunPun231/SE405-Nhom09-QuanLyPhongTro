package com.roomrental.modules.motel.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.motel.application.dto.MotelResult;
import com.roomrental.modules.motel.application.dto.MotelUpsertCommand;
import com.roomrental.modules.motel.application.event.MotelCreatedEvent;
import com.roomrental.modules.motel.application.event.MotelDeletedEvent;
import com.roomrental.modules.motel.application.event.MotelUpdatedEvent;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * Application service for Motel management (UC20-UC25).
 */
@Service
public class MotelService {

    private final MotelRepository motelRepository;
    private final ApplicationEventPublisher eventPublisher;
    private static final ObjectMapper objectMapper = new ObjectMapper();

    public MotelService(MotelRepository motelRepository, ApplicationEventPublisher eventPublisher) {
        this.motelRepository = motelRepository;
        this.eventPublisher = eventPublisher;
    }

    /**
     * UC20: Create a new motel.
     */
    @Transactional
    public MotelResult create(MotelUpsertCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();

        Motel motel = new Motel();
        motel.setTenantId(tenantId);
        motel.setName(command.name());
        motel.setAddress(command.address());
        motel.setTotalFloors(command.totalFloors());
        motel.setDescription(command.description());
        if (command.billingCycleDay() != null) {
            validateBillingCycleDay(command.billingCycleDay());
            motel.setBillingCycleDay(command.billingCycleDay());
        }
        if (command.depositPercent() != null) {
            validateDepositPercent(command.depositPercent());
            motel.setDepositPercent(command.depositPercent());
        }
        if (command.bankConfig() != null) {
            motel.setBankConfig(command.bankConfig());
        } else {
            String secretKey = generateSecureRandomSecret();
            motel.setBankConfig("{\"secretKey\":\"" + secretKey + "\"}");
        }

        MotelResult result = toResult(motelRepository.save(motel));
        eventPublisher.publishEvent(new MotelCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), result.name()));
        return result;
    }

    /**
     * UC21: List motels with pagination.
     */
    @Transactional(readOnly = true)
    public PageResponse<MotelResult> list(Pageable pageable) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Page<Motel> page = motelRepository.findByTenantId(tenantId, pageable);
        return PageResponse.from(page, this::toResult);
    }

    /**
     * UC22: Get motel detail.
     */
    @Transactional
    public MotelResult get(Long id) {
        Motel motel = findMotel(id);
        String config = motel.getBankConfig();
        boolean updated = false;
        if (config == null || config.isBlank()) {
            String secretKey = generateSecureRandomSecret();
            motel.setBankConfig("{\"secretKey\":\"" + secretKey + "\"}");
            updated = true;
        } else {
            try {
                JsonNode node = objectMapper.readTree(config);
                if (!node.has("secretKey") || node.get("secretKey").asText().isBlank()) {
                    ObjectNode objectNode = (ObjectNode) node;
                    objectNode.put("secretKey", generateSecureRandomSecret());
                    motel.setBankConfig(objectMapper.writeValueAsString(objectNode));
                    updated = true;
                }
            } catch (Exception e) {
                String secretKey = generateSecureRandomSecret();
                motel.setBankConfig("{\"secretKey\":\"" + secretKey + "\"}");
                updated = true;
            }
        }
        if (updated) {
            motel = motelRepository.save(motel);
        }
        return toResult(motel);
    }

    /**
     * UC23: Update motel info (partial update).
     */
    @Transactional
    public MotelResult update(Long id, MotelUpsertCommand command) {
        Motel motel = findMotel(id);
        String oldName = motel.getName();

        if (command.name() != null && !command.name().isBlank()) {
            motel.setName(command.name());
        }
        if (command.address() != null && !command.address().isBlank()) {
            motel.setAddress(command.address());
        }
        if (command.totalFloors() != null) {
            if (command.totalFloors() < 1) {
                throw BaseException.badRequest("totalFloors must be at least 1");
            }
            motel.setTotalFloors(command.totalFloors());
        }
        if (command.description() != null) {
            motel.setDescription(command.description());
        }
        if (command.billingCycleDay() != null) {
            validateBillingCycleDay(command.billingCycleDay());
            motel.setBillingCycleDay(command.billingCycleDay());
        }
        if (command.depositPercent() != null) {
            validateDepositPercent(command.depositPercent());
            motel.setDepositPercent(command.depositPercent());
        }
        if (command.bankConfig() != null) {
            String newConfig = command.bankConfig();
            String oldConfig = motel.getBankConfig();
            if (newConfig != null && !newConfig.isBlank()) {
                try {
                    JsonNode newRoot = objectMapper.readTree(newConfig);
                    if (newRoot.has("sePayApiKey")) {
                        String newKey = newRoot.get("sePayApiKey").asText();
                        ObjectNode nodeToSave = (ObjectNode) newRoot;
                        
                        if (newKey.contains("•") || newKey.contains("*")) {
                            // Recover old keys
                            if (oldConfig != null && !oldConfig.isBlank()) {
                                JsonNode oldRoot = objectMapper.readTree(oldConfig);
                                if (oldRoot.has("sePayApiKey")) {
                                    nodeToSave.put("sePayApiKey", oldRoot.get("sePayApiKey").asText());
                                }
                                if (oldRoot.has("secretKey")) {
                                    nodeToSave.put("secretKey", oldRoot.get("secretKey").asText());
                                }
                                if (oldRoot.has("webhookId")) {
                                    nodeToSave.put("webhookId", oldRoot.get("webhookId").asText());
                                }
                            }
                        } else if (!newKey.isBlank()) {
                            // Encrypt plaintext key
                            com.roomrental.common.security.AesCryptoConverter cryptoConverter = new com.roomrental.common.security.AesCryptoConverter();
                            nodeToSave.put("sePayApiKey", cryptoConverter.convertToDatabaseColumn(newKey.trim()));
                        }
                        newConfig = objectMapper.writeValueAsString(nodeToSave);
                    }
                } catch (Exception e) {
                    // Fallback to saving raw command string if parsing fails
                }
            }
            motel.setBankConfig(newConfig);
        }

        MotelResult result = toResult(motelRepository.save(motel));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new MotelUpdatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldName, result.name()));
        return result;
    }

    /**
     * UC25: Soft-delete motel.
     */
    @Transactional
    public void delete(Long id) {
        Motel motel = findMotel(id);
        motel.setDeleted(true);
        motelRepository.save(motel);

        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new MotelDeletedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                id, motel.getName()));
    }

    @Transactional
    public void savePaymentConfig(Long motelId, String accountNumber, String bankName) {
        Motel motel = findMotel(motelId);
        String existingConfig = motel.getBankConfig();
        String secretKey = null;
        String webhookId = null;
        String sePayApiKey = null;
        String accountHolder = "CHỦ TRỌ";

        if (existingConfig != null && !existingConfig.isBlank()) {
            try {
                JsonNode node = objectMapper.readTree(existingConfig);
                if (node.has("secretKey")) {
                    secretKey = node.get("secretKey").asText();
                }
                if (node.has("webhookId")) {
                    webhookId = node.get("webhookId").asText();
                }
                if (node.has("sePayApiKey")) {
                    sePayApiKey = node.get("sePayApiKey").asText();
                }
                if (node.has("accountHolder")) {
                    accountHolder = node.get("accountHolder").asText();
                }
            } catch (Exception ignored) {}
        }

        if (secretKey == null || secretKey.isBlank()) {
            secretKey = generateSecureRandomSecret();
        }

        String bankId = deriveBankId(bankName);

        // Construct new bank_config JSON
        java.util.Map<String, String> configMap = new java.util.HashMap<>();
        configMap.put("bankId", bankId);
        configMap.put("bankAccount", accountNumber.trim());
        configMap.put("accountHolder", accountHolder);
        configMap.put("bankName", bankName);
        if (sePayApiKey != null) {
            configMap.put("sePayApiKey", sePayApiKey);
        }
        configMap.put("secretKey", secretKey);
        if (webhookId != null) {
            configMap.put("webhookId", webhookId);
        }

        try {
            String jsonConfig = objectMapper.writeValueAsString(configMap);
            motel.setBankConfig(jsonConfig);
            motelRepository.save(motel);
        } catch (Exception e) {
            throw new BaseException(HttpStatus.INTERNAL_SERVER_ERROR, "JSON_ERROR", "Failed to construct bank configuration");
        }
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

    public String generateSecureRandomSecret() {
        byte[] randomBytes = new byte[24];
        new java.security.SecureRandom().nextBytes(randomBytes);
        return java.util.Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
    }

    private Motel findMotel(Long id) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return motelRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Motel", id));
    }

    private MotelResult toResult(Motel motel) {
        return new MotelResult(
                motel.getId(),
                motel.getTenantId().toString(),
                motel.getName(),
                motel.getAddress(),
                motel.getTotalFloors(),
                motel.getDescription(),
                motel.getBillingCycleDay(),
                motel.getDepositPercent(),
                motel.getBankConfig()
        );
    }

    private void validateBillingCycleDay(Integer billingCycleDay) {
        if (billingCycleDay < 1 || billingCycleDay > 28) {
            throw BaseException.badRequest("billingCycleDay must be between 1 and 28");
        }
    }

    private void validateDepositPercent(java.math.BigDecimal depositPercent) {
        if (depositPercent.compareTo(java.math.BigDecimal.ZERO) < 0
                || depositPercent.compareTo(new java.math.BigDecimal("100")) > 0) {
            throw BaseException.badRequest("depositPercent must be between 0 and 100");
        }
    }
}

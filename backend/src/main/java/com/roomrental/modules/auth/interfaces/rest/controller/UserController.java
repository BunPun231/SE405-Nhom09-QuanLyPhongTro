package com.roomrental.modules.auth.interfaces.rest.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.auth.application.dto.OnboardingStatusResult;
import com.roomrental.modules.auth.domain.model.User;
import com.roomrental.modules.auth.domain.repository.UserRepository;
import com.roomrental.modules.motel.infrastructure.persistence.MotelJpaRepository;
import com.roomrental.modules.room.infrastructure.repository.RoomJpaRepository;
import com.roomrental.modules.contract.infrastructure.persistence.ContractJpaRepository;
import com.roomrental.modules.finance.infrastructure.persistence.MeterReadingJpaRepository;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceJpaRepository;
import com.roomrental.modules.service.infrastructure.repository.ServiceJpaRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "User Profile", description = "Endpoints for managing user profile and onboarding")
public class UserController {

    private final UserRepository userRepository;
    private final MotelJpaRepository motelJpaRepository;
    private final RoomJpaRepository roomJpaRepository;
    private final ContractJpaRepository contractJpaRepository;
    private final MeterReadingJpaRepository meterReadingJpaRepository;
    private final InvoiceJpaRepository invoiceJpaRepository;
    private final ServiceJpaRepository serviceJpaRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public UserController(
            UserRepository userRepository,
            MotelJpaRepository motelJpaRepository,
            RoomJpaRepository roomJpaRepository,
            ContractJpaRepository contractJpaRepository,
            MeterReadingJpaRepository meterReadingJpaRepository,
            InvoiceJpaRepository invoiceJpaRepository,
            ServiceJpaRepository serviceJpaRepository) {
        this.userRepository = userRepository;
        this.motelJpaRepository = motelJpaRepository;
        this.roomJpaRepository = roomJpaRepository;
        this.contractJpaRepository = contractJpaRepository;
        this.meterReadingJpaRepository = meterReadingJpaRepository;
        this.invoiceJpaRepository = invoiceJpaRepository;
        this.serviceJpaRepository = serviceJpaRepository;
    }

    @PutMapping("/onboarding-complete")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Mark onboarding as completed for the current user")
    public ResponseEntity<ApiResponse<Void>> completeOnboarding() {
        UUID userId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> com.roomrental.common.exception.BaseException.notFound("User", userId));
        user.setHasCompletedOnboarding(true);
        userRepository.save(user);
        return ResponseEntity.ok(ApiResponse.ok("Onboarding completed successfully"));
    }

    @GetMapping("/onboarding-status")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TENANT','RESIDENT')")
    @Operation(summary = "Get the real-time onboarding checklist status for the current user")
    public ResponseEntity<ApiResponse<OnboardingStatusResult>> getOnboardingStatus() {
        UUID userId = SecurityUtils.getCurrentUserId();
        UUID tenantId = SecurityUtils.requireTenantId();

        User user = userRepository.findById(userId)
                .orElseThrow(() -> com.roomrental.common.exception.BaseException.notFound("User", userId));

        boolean hasCompletedOnboarding = user.isHasCompletedOnboarding();
        boolean hasMotel = motelJpaRepository.countByTenantIdAndDeletedFalse(tenantId) > 0;
        
        boolean hasSePayConfig = false;
        var motels = motelJpaRepository.findByTenantIdAndDeletedFalse(tenantId);
        for (var motel : motels) {
            String bankConfig = motel.getBankConfig();
            if (bankConfig != null && !bankConfig.isBlank()) {
                try {
                    var node = objectMapper.readTree(bankConfig);
                    if (node.has("secretKey") && !node.get("secretKey").asText().isBlank()
                            && node.has("bankAccount") && !node.get("bankAccount").asText().isBlank()) {
                        hasSePayConfig = true;
                        break;
                    }
                } catch (Exception ignored) {}
            }
        }

        boolean hasRooms = roomJpaRepository.countByTenantId(tenantId) > 0;
        
        boolean hasServicesConfig = false;
        for (var motel : motels) {
            if (serviceJpaRepository.countByMotelId(motel.getId()) > 2) {
                hasServicesConfig = true;
                break;
            }
        }

        boolean hasActiveContract = contractJpaRepository.countActiveByTenantId(tenantId) > 0;
        boolean hasMeterReadings = meterReadingJpaRepository.countByTenantId(tenantId) > 0;
        boolean hasInvoice = invoiceJpaRepository.countByTenantIdAndIsDeletedFalse(tenantId) > 0;

        int currentStep = 1;
        if (!hasMotel || !hasSePayConfig) {
            currentStep = 1;
        } else if (!hasRooms) {
            currentStep = 2;
        } else if (!hasServicesConfig) {
            currentStep = 3;
        } else if (!hasActiveContract) {
            currentStep = 4;
        } else if (!hasMeterReadings) {
            currentStep = 5;
        } else if (!hasInvoice) {
            currentStep = 6;
        } else {
            currentStep = 7;
        }

        OnboardingStatusResult result = new OnboardingStatusResult(
                hasCompletedOnboarding,
                hasMotel,
                hasSePayConfig,
                hasRooms,
                hasActiveContract,
                hasMeterReadings,
                hasInvoice,
                currentStep
        );

        return ResponseEntity.ok(ApiResponse.ok(result));
    }
}

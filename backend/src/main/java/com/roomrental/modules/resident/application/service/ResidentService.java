package com.roomrental.modules.resident.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import com.roomrental.modules.resident.application.dto.ResidentCreateCommand;
import com.roomrental.modules.resident.application.dto.ResidentResult;
import com.roomrental.modules.resident.application.dto.ResidentUpdateCommand;
import com.roomrental.modules.resident.application.event.ResidentCreatedEvent;
import com.roomrental.modules.resident.application.event.ResidentDeactivatedEvent;
import com.roomrental.modules.resident.application.event.ResidentReactivatedEvent;
import com.roomrental.modules.resident.infrastructure.entity.ResidentProfileEntity;
import com.roomrental.modules.resident.infrastructure.repository.ResidentProfileJpaRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Application service for Resident management (UC49-UC55).
 * Creates User (role=RESIDENT) + ResidentProfile in a single transaction.
 */
@Service
public class ResidentService {

    private final UserJpaRepository userJpaRepository;
    private final ResidentProfileJpaRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;

    public ResidentService(
            UserJpaRepository userJpaRepository,
            ResidentProfileJpaRepository profileRepository,
            PasswordEncoder passwordEncoder,
            ApplicationEventPublisher eventPublisher
    ) {
        this.userJpaRepository = userJpaRepository;
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.eventPublisher = eventPublisher;
    }

    /**
     * UC49: Add new resident.
     * Creates a user account (phone as login, default password) + resident profile.
     */
    @Transactional
    public ResidentResult create(ResidentCreateCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();

        // Check if phone already registered
        var existingUser = userJpaRepository.findByPhone(command.phone());
        if (existingUser.isPresent()) {
            UserEntity user = existingUser.get();
            // If INACTIVE, reactivate and update details
            if ("INACTIVE".equals(user.getStatus())) {
                user.setFullName(command.fullName());
                user.setEmail(command.email());
                user.setStatus("ACTIVE");
                user.setMustChangePassword(false); // keep old password, user already exists
                user = userJpaRepository.save(user);

                // Update resident profile
                ResidentProfileEntity profile = profileRepository.findById(user.getId())
                        .orElse(new ResidentProfileEntity());
                profile.setUserId(user.getId());
                profile.setIdCardNumber(command.idCardNumber());
                profile.setIdCardFrontUrl(command.idCardFrontUrl());
                profile.setIdCardBackUrl(command.idCardBackUrl());
                profileRepository.save(profile);

                ResidentResult result = toResult(user, profile);
                eventPublisher.publishEvent(new ResidentReactivatedEvent(
                        tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                        result.userId()));
                return result;
            }
            // If ACTIVE, throw conflict
            throw new BaseException(HttpStatus.CONFLICT, "PHONE_EXISTS", "Phone already registered");
        }
        if (profileRepository.existsByIdCardNumberAndTenantId(command.idCardNumber(), tenantId)) {
            throw BaseException.conflict("ID card number already exists");
        }

        // Create user with role RESIDENT
        UserEntity user = new UserEntity();
        user.setTenantId(tenantId);
        user.setPhone(command.phone());
        user.setEmail(command.email());
        user.setFullName(command.fullName());
        user.setPasswordHash(passwordEncoder.encode(command.phone())); // default password = phone
        user.setRole("RESIDENT");
        user.setStatus("ACTIVE");
        user.setMustChangePassword(true);
        user = userJpaRepository.save(user);

        // Create resident profile
        ResidentProfileEntity profile = new ResidentProfileEntity();
        profile.setUserId(user.getId());
        profile.setIdCardNumber(command.idCardNumber());
        profile.setIdCardFrontUrl(command.idCardFrontUrl());
        profile.setIdCardBackUrl(command.idCardBackUrl());
        profileRepository.save(profile);

        ResidentResult result = toResult(user, profile);
        eventPublisher.publishEvent(new ResidentCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.userId(), result.fullName()));
        return result;
    }

    /**
     * UC50: List residents in tenant with pagination.
     */
    @Transactional(readOnly = true)
    public PageResponse<ResidentResult> list(Pageable pageable) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Page<UserEntity> users = userJpaRepository.findByTenantIdAndRole(tenantId, "RESIDENT", pageable);
        return PageResponse.from(users, u -> {
            ResidentProfileEntity profile = profileRepository.findById(u.getId()).orElse(null);
            return toResult(u, profile);
        });
    }

    /**
     * UC51: Get resident detail.
     */
    @Transactional(readOnly = true)
    public ResidentResult get(UUID residentId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = userJpaRepository.findById(residentId)
                .filter(u -> tenantId.equals(u.getTenantId()) && "RESIDENT".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Resident", residentId));
        ResidentProfileEntity profile = profileRepository.findById(residentId).orElse(null);
        return toResult(user, profile);
    }

    /**
     * UC53: Update resident profile.
     * Phone cannot be changed as it is the login credential.
     */
    @Transactional
    public ResidentResult update(ResidentUpdateCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = userJpaRepository.findById(command.residentId())
                .filter(u -> tenantId.equals(u.getTenantId()) && "RESIDENT".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Resident", command.residentId()));

        if (command.fullName() != null) user.setFullName(command.fullName());
        if (command.email() != null) user.setEmail(command.email());
        user = userJpaRepository.save(user);

        ResidentProfileEntity profile = profileRepository.findById(command.residentId())
                .orElse(new ResidentProfileEntity());
        profile.setUserId(user.getId());
        if (command.idCardNumber() != null) profile.setIdCardNumber(command.idCardNumber());
        if (command.idCardFrontUrl() != null) profile.setIdCardFrontUrl(command.idCardFrontUrl());
        if (command.idCardBackUrl() != null) profile.setIdCardBackUrl(command.idCardBackUrl());
        profileRepository.save(profile);

        return toResult(user, profile);
    }

    /**
     * UC54: Deactivate resident.
     */
    @Transactional
    public void deactivate(UUID residentId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = userJpaRepository.findById(residentId)
                .filter(u -> tenantId.equals(u.getTenantId()) && "RESIDENT".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Resident", residentId));
        String oldStatus = user.getStatus();
        user.setStatus("INACTIVE");
        userJpaRepository.save(user);

        eventPublisher.publishEvent(new ResidentDeactivatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                residentId, oldStatus));
    }

    private ResidentResult toResult(UserEntity user, ResidentProfileEntity profile) {
        return new ResidentResult(
                user.getId(), user.getPhone(), user.getEmail(), user.getFullName(),
                user.getStatus(), profile != null ? profile.getIdCardNumber() : null
        );
    }
}

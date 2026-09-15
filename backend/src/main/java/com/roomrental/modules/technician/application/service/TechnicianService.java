package com.roomrental.modules.technician.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import com.roomrental.modules.technician.application.dto.TechnicianCreateCommand;
import com.roomrental.modules.technician.application.dto.TechnicianResult;
import com.roomrental.modules.technician.application.event.TechnicianCreatedEvent;
import com.roomrental.modules.technician.application.event.TechnicianLockedEvent;
import com.roomrental.modules.technician.application.event.TechnicianPasswordResetEvent;
import com.roomrental.modules.technician.infrastructure.entity.TechnicianProfileEntity;
import com.roomrental.modules.technician.infrastructure.repository.TechnicianProfileJpaRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

/**
 * Application service for Technician management (UC56-UC62).
 */
@Service
public class TechnicianService {

    private final UserJpaRepository userJpaRepository;
    private final TechnicianProfileJpaRepository profileRepository;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;

    public TechnicianService(
            UserJpaRepository userJpaRepository,
            TechnicianProfileJpaRepository profileRepository,
            PasswordEncoder passwordEncoder,
            ApplicationEventPublisher eventPublisher
    ) {
        this.userJpaRepository = userJpaRepository;
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.eventPublisher = eventPublisher;
    }

    /**
     * UC56: Add technician.
     * Creates user (role=TECHNICIAN) + technician_profile.
     */
    @Transactional
    public TechnicianResult create(TechnicianCreateCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();

        if (userJpaRepository.existsByPhone(command.phone())) {
            throw new BaseException(HttpStatus.CONFLICT, "PHONE_EXISTS", "Phone already registered");
        }

        UserEntity user = new UserEntity();
        user.setTenantId(tenantId);
        user.setPhone(command.phone());
        user.setEmail(command.email());
        user.setFullName(command.fullName());
        user.setPasswordHash(passwordEncoder.encode(command.phone()));
        user.setRole("TECHNICIAN");
        user.setStatus("ACTIVE");
        user.setMustChangePassword(true);
        user = userJpaRepository.save(user);

        TechnicianProfileEntity profile = new TechnicianProfileEntity();
        profile.setUserId(user.getId());
        profile.setExpertise(command.expertise() != null ? command.expertise().toArray(String[]::new) : null);
        profile.setAssignedMotelIds(command.assignedMotelIds() != null ? command.assignedMotelIds().toArray(Integer[]::new) : null);
        profile.setAvailable(true);
        profileRepository.save(profile);

        TechnicianResult result = toResult(user, profile);
        eventPublisher.publishEvent(new TechnicianCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.userId(), result.fullName()));
        return result;
    }

    @Transactional(readOnly = true)
    public PageResponse<TechnicianResult> list(Pageable pageable) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return PageResponse.from(
                userJpaRepository.findByTenantIdAndRole(tenantId, "TECHNICIAN", pageable),
                u -> {
                    TechnicianProfileEntity p = profileRepository.findById(u.getId()).orElse(null);
                    return toResult(u, p);
                }
        );
    }

    @Transactional(readOnly = true)
    public TechnicianResult get(UUID techId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = userJpaRepository.findById(techId)
                .filter(u -> tenantId.equals(u.getTenantId()) && "TECHNICIAN".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Technician", techId));
        TechnicianProfileEntity p = profileRepository.findById(techId).orElse(null);
        return toResult(user, p);
    }

    /**
     * UC60: Lock technician account.
     */
    @Transactional
    public void lock(UUID techId, String reason) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = userJpaRepository.findById(techId)
                .filter(u -> tenantId.equals(u.getTenantId()) && "TECHNICIAN".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Technician", techId));
        String oldStatus = user.getStatus();
        user.setStatus("LOCKED");
        user.setLockReason(reason);
        userJpaRepository.save(user);

        eventPublisher.publishEvent(new TechnicianLockedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                techId, oldStatus, reason));
    }

    /**
     * UC62: Reset technician password.
     */
    @Transactional
    public void resetPassword(UUID techId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = userJpaRepository.findById(techId)
                .filter(u -> tenantId.equals(u.getTenantId()) && "TECHNICIAN".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Technician", techId));
        user.setPasswordHash(passwordEncoder.encode(user.getPhone()));
        user.setMustChangePassword(true);
        userJpaRepository.save(user);

        eventPublisher.publishEvent(new TechnicianPasswordResetEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                techId));
    }

    private TechnicianResult toResult(UserEntity user, TechnicianProfileEntity p) {
        return new TechnicianResult(
                user.getId(), user.getPhone(), user.getEmail(), user.getFullName(), user.getStatus(),
                p != null && p.getExpertise() != null ? Arrays.asList(p.getExpertise()) : List.of(),
                p != null && p.isAvailable(),
                p != null && p.getAssignedMotelIds() != null ? Arrays.asList(p.getAssignedMotelIds()) : List.of()
        );
    }
}

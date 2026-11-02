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
import com.roomrental.modules.resident.application.event.ResidentUpdatedEvent;
import com.roomrental.modules.resident.infrastructure.entity.ResidentProfileEntity;
import com.roomrental.modules.resident.infrastructure.repository.ResidentProfileJpaRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Objects;
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
    private final ResidentQueryService queryService;
    private final NamedParameterJdbcTemplate jdbc;

    public ResidentService(
            UserJpaRepository userJpaRepository,
            ResidentProfileJpaRepository profileRepository,
            PasswordEncoder passwordEncoder,
            ApplicationEventPublisher eventPublisher,
            ResidentQueryService queryService,
            NamedParameterJdbcTemplate jdbc
    ) {
        this.userJpaRepository = userJpaRepository;
        this.profileRepository = profileRepository;
        this.passwordEncoder = passwordEncoder;
        this.eventPublisher = eventPublisher;
        this.queryService = queryService;
        this.jdbc = jdbc;
    }

    /**
     * UC49: Add new resident.
     * Creates a user account (phone as login, default password) + resident profile.
     * Optionally links the new resident to an existing contract (co-resident).
     */
    @Transactional
    public ResidentResult create(ResidentCreateCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();
        if (command.contractId() != null) {
            requireLinkableContract(command.contractId(), tenantId);
        }

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
                if (notBlank(command.avatarUrl())) user.setAvatarUrl(command.avatarUrl());
                user = userJpaRepository.save(user);

                // Update resident profile
                ResidentProfileEntity profile = profileRepository.findById(user.getId())
                        .orElse(new ResidentProfileEntity());
                profile.setUserId(user.getId());
                profile.setIdCardNumber(command.idCardNumber());
                profile.setIdCardFrontUrl(command.idCardFrontUrl());
                profile.setIdCardBackUrl(command.idCardBackUrl());
                applyExtraFields(profile, command.dateOfBirth(), command.gender(), command.notes());
                profileRepository.save(profile);

                linkToContract(command.contractId(), user.getId(), tenantId);
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
        if (notBlank(command.avatarUrl())) user.setAvatarUrl(command.avatarUrl());
        user = userJpaRepository.save(user);

        // Create resident profile
        ResidentProfileEntity profile = new ResidentProfileEntity();
        profile.setUserId(user.getId());
        profile.setIdCardNumber(command.idCardNumber());
        profile.setIdCardFrontUrl(command.idCardFrontUrl());
        profile.setIdCardBackUrl(command.idCardBackUrl());
        applyExtraFields(profile, command.dateOfBirth(), command.gender(), command.notes());
        profileRepository.save(profile);

        linkToContract(command.contractId(), user.getId(), tenantId);
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
        UserEntity user = requireResident(residentId);
        ResidentProfileEntity profile = profileRepository.findById(residentId).orElse(null);
        return toResult(user, profile);
    }

    /**
     * UC53: Update resident profile.
     * Phone (login) can be changed if not used by another account.
     * Every changed field is written to the activity log (Audit: log all changes).
     */
    @Transactional
    public ResidentResult update(ResidentUpdateCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = requireResident(command.residentId());
        ResidentProfileEntity profile = profileRepository.findById(command.residentId())
                .orElse(new ResidentProfileEntity());
        profile.setUserId(user.getId());

        UUID actorId = SecurityUtils.getCurrentUserId();
        String actorRole = SecurityUtils.getCurrentRole();
        UUID rid = user.getId();

        if (command.phone() != null && !command.phone().isBlank()
                && !command.phone().trim().equals(user.getPhone())) {
            String phone = command.phone().trim();
            if (userJpaRepository.existsByPhoneAndIdNot(phone, rid)) {
                throw new BaseException(HttpStatus.CONFLICT, "PHONE_EXISTS", "Số điện thoại đã được sử dụng");
            }
            audit(tenantId, actorId, actorRole, rid, "phone", user.getPhone(), phone);
            user.setPhone(phone);
        }
        if (command.fullName() != null && !command.fullName().isBlank()
                && !command.fullName().trim().equals(user.getFullName())) {
            audit(tenantId, actorId, actorRole, rid, "fullName", user.getFullName(), command.fullName().trim());
            user.setFullName(command.fullName().trim());
        }
        if (command.email() != null) {
            String email = command.email().isBlank() ? null : command.email().trim();
            if (!Objects.equals(email, user.getEmail())) {
                audit(tenantId, actorId, actorRole, rid, "email", user.getEmail(), email);
                user.setEmail(email);
            }
        }
        if (command.avatarUrl() != null && !command.avatarUrl().equals(user.getAvatarUrl())) {
            audit(tenantId, actorId, actorRole, rid, "avatar", null, "(ảnh mới)");
            user.setAvatarUrl(command.avatarUrl().isBlank() ? null : command.avatarUrl());
        }
        user = userJpaRepository.save(user);

        if (command.idCardNumber() != null && !command.idCardNumber().isBlank()
                && !command.idCardNumber().trim().equals(profile.getIdCardNumber())) {
            String idCard = command.idCardNumber().trim();
            if (profileRepository.existsByIdCardNumberAndTenantId(idCard, tenantId)) {
                throw BaseException.conflict("ID card number already exists");
            }
            audit(tenantId, actorId, actorRole, rid, "idCardNumber",
                    mask(profile.getIdCardNumber()), mask(idCard));
            profile.setIdCardNumber(idCard);
        }
        if (command.idCardFrontUrl() != null) profile.setIdCardFrontUrl(command.idCardFrontUrl());
        if (command.idCardBackUrl() != null) profile.setIdCardBackUrl(command.idCardBackUrl());
        if (command.notes() != null) {
            String notes = command.notes().isBlank() ? null : command.notes().trim();
            if (!Objects.equals(notes, profile.getNotes())) {
                audit(tenantId, actorId, actorRole, rid, "notes", profile.getNotes(), notes);
                profile.setNotes(notes);
            }
        }
        if (command.dateOfBirth() != null && !command.dateOfBirth().equals(profile.getDateOfBirth())) {
            audit(tenantId, actorId, actorRole, rid, "dateOfBirth",
                    Objects.toString(profile.getDateOfBirth(), null), command.dateOfBirth().toString());
            profile.setDateOfBirth(command.dateOfBirth());
        }
        if (command.gender() != null && !command.gender().isBlank()
                && !command.gender().equals(profile.getGender())) {
            audit(tenantId, actorId, actorRole, rid, "gender", profile.getGender(), command.gender());
            profile.setGender(command.gender());
        }
        profileRepository.save(profile);

        return toResult(user, profile);
    }

    /**
     * UC54: Deactivate resident.
     * Only allowed when every contract is liquidated/canceled and no invoice is unpaid
     * (BR54.2). Login is revoked immediately by bumping the session version (BR54.5).
     */
    @Transactional
    public void deactivate(UUID residentId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UserEntity user = requireResident(residentId);
        String blockReason = queryService.deactivateBlockReason(residentId, user.getStatus());
        if (blockReason != null) {
            throw new BaseException(HttpStatus.CONFLICT, "RESIDENT_NOT_SETTLED", blockReason);
        }
        String oldStatus = user.getStatus();
        user.setStatus("INACTIVE");
        user.setSessionVersion(user.getSessionVersion() == null ? 1 : user.getSessionVersion() + 1);
        userJpaRepository.save(user);

        eventPublisher.publishEvent(new ResidentDeactivatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                residentId, oldStatus));
    }

    private UserEntity requireResident(UUID residentId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return userJpaRepository.findById(residentId)
                .filter(u -> tenantId.equals(u.getTenantId()) && "RESIDENT".equals(u.getRole()))
                .orElseThrow(() -> BaseException.notFound("Resident", residentId));
    }

    /** UC49: the contract to link must belong to the workspace and still be open. */
    private void requireLinkableContract(Long contractId, UUID tenantId) {
        List<String> statuses = jdbc.queryForList(
                "SELECT status FROM contracts WHERE id = :id AND tenant_id = :tenantId",
                new MapSqlParameterSource().addValue("id", contractId).addValue("tenantId", tenantId),
                String.class);
        if (statuses.isEmpty()) {
            throw BaseException.notFound("Contract", contractId);
        }
        if (!List.of("ACTIVE", "DRAFT").contains(statuses.get(0))) {
            throw BaseException.badRequest("Chỉ có thể thêm khách vào hợp đồng đang hiệu lực hoặc chờ cọc");
        }
    }

    /** UC49: add the resident to contract_residents and update room headcount. */
    private void linkToContract(Long contractId, UUID residentId, UUID tenantId) {
        if (contractId == null) return;
        MapSqlParameterSource p = new MapSqlParameterSource()
                .addValue("cid", contractId)
                .addValue("uid", residentId)
                .addValue("tenantId", tenantId);
        int inserted = jdbc.update("""
                INSERT INTO contract_residents (contract_id, resident_user_id, tenant_id, is_active, joined_at)
                VALUES (:cid, :uid, :tenantId, TRUE, CURRENT_TIMESTAMP)
                ON CONFLICT (contract_id, resident_user_id)
                DO UPDATE SET is_active = TRUE, left_at = NULL
                """, p);
        if (inserted > 0) {
            jdbc.update("""
                    UPDATE rooms SET current_residents_count = current_residents_count + 1
                    WHERE id = (SELECT room_id FROM contracts WHERE id = :cid AND tenant_id = :tenantId)
                    """, p);
        }
    }

    private void audit(UUID tenantId, UUID actorId, String actorRole, UUID residentId,
                       String field, String oldValue, String newValue) {
        eventPublisher.publishEvent(new ResidentUpdatedEvent(
                tenantId, actorId, actorRole, residentId, field, oldValue, newValue));
    }

    static String mask(String idCard) {
        if (idCard == null || idCard.length() <= 4) return idCard;
        return "*".repeat(idCard.length() - 4) + idCard.substring(idCard.length() - 4);
    }

    private static void applyExtraFields(ResidentProfileEntity profile, LocalDate dob, String gender, String notes) {
        if (dob != null) profile.setDateOfBirth(dob);
        if (notBlank(gender)) profile.setGender(gender);
        if (notBlank(notes)) profile.setNotes(notes.trim());
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private ResidentResult toResult(UserEntity user, ResidentProfileEntity profile) {
        return new ResidentResult(
                user.getId(), user.getPhone(), user.getEmail(), user.getFullName(),
                user.getStatus(),
                profile != null ? profile.getIdCardNumber() : null,
                profile != null ? profile.getIdCardFrontUrl() : null,
                profile != null ? profile.getIdCardBackUrl() : null,
                user.getAvatarUrl(),
                profile != null ? profile.getDateOfBirth() : null,
                profile != null ? profile.getGender() : null,
                profile != null ? profile.getNotes() : null
        );
    }
}

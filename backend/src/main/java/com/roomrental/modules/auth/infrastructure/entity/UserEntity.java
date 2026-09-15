package com.roomrental.modules.auth.infrastructure.entity;

import com.roomrental.common.entity.BaseEntity;
import com.roomrental.common.security.AesCryptoConverter;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * JPA Entity mapping to DB table "users".
 * All fields synced with database.sql schema.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
public class UserEntity extends BaseEntity {

    @Id
    private UUID id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(nullable = false, unique = true, length = 15)
    private String phone;

    @Column(length = 255)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "national_id", length = 20)
    private String nationalId;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "bank_account_number", length = 30)
    private String bankAccountNumber;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "bank_account_name", length = 100)
    private String bankAccountName;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "bank_name", length = 100)
    private String bankName;

    @Column(nullable = false, length = 20)
    private String role;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "must_change_password", nullable = false)
    private boolean mustChangePassword;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "last_login_at")
    private OffsetDateTime lastLoginAt;

    @Column(name = "lock_reason")
    private String lockReason;

    @Column(name = "session_version", nullable = false)
    private Integer sessionVersion = 0;

    @Column(name = "has_completed_onboarding", nullable = false)
    private boolean hasCompletedOnboarding = false;

    @PrePersist
    void prePersist() {
        if (id == null) {
            id = UUID.randomUUID();
        }
    }
}

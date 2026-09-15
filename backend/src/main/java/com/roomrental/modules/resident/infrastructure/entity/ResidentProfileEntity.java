package com.roomrental.modules.resident.infrastructure.entity;

import com.roomrental.common.security.AesCryptoConverter;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "resident_profiles")
@Getter @Setter @NoArgsConstructor
public class ResidentProfileEntity {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "id_card_number", nullable = false, length = 255)
    private String idCardNumber;

    @Column(name = "id_card_front_url")
    private String idCardFrontUrl;

    @Column(name = "id_card_back_url")
    private String idCardBackUrl;

    @Column(name = "verified_at")
    private OffsetDateTime verifiedAt;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "bank_account_number", length = 30)
    private String bankAccountNumber;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "bank_account_name", length = 100)
    private String bankAccountName;

    @Convert(converter = AesCryptoConverter.class)
    @Column(name = "bank_name", length = 100)
    private String bankName;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}

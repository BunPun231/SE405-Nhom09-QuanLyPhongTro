package com.roomrental.modules.auth.infrastructure.entity;

import com.roomrental.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

/**
 * JPA Entity mapping to DB table "tenants".
 * Fields synced with database.sql schema.
 */
@Entity
@Table(name = "tenants")
@Getter
@Setter
@NoArgsConstructor
public class TenantEntity extends BaseEntity {

    @Id
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(name = "owner_user_id", nullable = false)
    private UUID ownerUserId;

    @Column(nullable = false, length = 20)
    private String status;

    @PrePersist
    void prePersist() {
        if (id == null) {
            id = UUID.randomUUID();
        }
    }
}

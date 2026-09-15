package com.roomrental.modules.motel.infrastructure.persistence;

import com.roomrental.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.SQLRestriction;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.util.UUID;

/**
 * JPA Entity mapping to DB table "motels".
 * Soft-delete filtered by @SQLRestriction.
 */
@Entity
@Table(name = "motels", uniqueConstraints = {
        @UniqueConstraint(name = "motels_tenant_name_unique", columnNames = {"tenant_id", "name"})
})
@SQLRestriction("is_deleted = false")
@Getter
@Setter
@NoArgsConstructor
public class MotelEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String address;

    @Column(name = "total_floors", nullable = false)
    private Integer totalFloors;

    @Column
    private String description;

    @Column(name = "billing_cycle_day")
    private Integer billingCycleDay;

    @Column(name = "deposit_percent", precision = 5, scale = 2)
    private java.math.BigDecimal depositPercent;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "bank_config", columnDefinition = "jsonb")
    private String bankConfig;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;
}

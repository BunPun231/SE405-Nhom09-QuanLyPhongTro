package com.roomrental.modules.service.infrastructure.entity;

import com.roomrental.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.SQLRestriction;

@Entity
@Table(name = "services", uniqueConstraints = {
        @UniqueConstraint(name = "services_motel_name_unique", columnNames = {"motel_id", "name"})
})
@SQLRestriction("is_deleted = false")
@Getter @Setter @NoArgsConstructor
public class ServiceEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "motel_id", nullable = false)
    private Long motelId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "charge_type", nullable = false, length = 20)
    private String chargeType;

    @Column(length = 20)
    private String unit;

    @Column(name = "is_mandatory", nullable = false)
    private boolean mandatory;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;
}

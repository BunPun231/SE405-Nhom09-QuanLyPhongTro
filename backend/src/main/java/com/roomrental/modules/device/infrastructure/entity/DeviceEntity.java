package com.roomrental.modules.device.infrastructure.entity;

import com.roomrental.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.SQLRestriction;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "devices")
@SQLRestriction("is_deleted = false")
@Getter @Setter @NoArgsConstructor
public class DeviceEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "motel_id", nullable = false)
    private Long motelId;

    @Column(nullable = false)
    private String name;

    @Column(length = 100)
    private String brand;

    @Column(name = "purchase_price", precision = 12, scale = 2)
    private BigDecimal purchasePrice;

    @Column(name = "purchase_date")
    private LocalDate purchaseDate;

    @Column(name = "total_quantity", nullable = false)
    private Integer totalQuantity = 1;

    @Column(name = "repairing_quantity", nullable = false)
    private Integer repairingQuantity = 0;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;

    // Getter and Setter for repairingQuantity are handled by Lombok

}

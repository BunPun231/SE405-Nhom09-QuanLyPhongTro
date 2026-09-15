package com.roomrental.modules.room.infrastructure.entity;

import com.roomrental.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.SQLRestriction;

import java.math.BigDecimal;

/**
 * JPA Entity mapping to DB table "rooms".
 */
@Entity
@Table(name = "rooms", uniqueConstraints = {
        @UniqueConstraint(name = "rooms_motel_room_unique", columnNames = {"motel_id", "room_number"})
})
@SQLRestriction("is_deleted = false")
@Getter
@Setter
@NoArgsConstructor
public class RoomEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "motel_id", nullable = false)
    private Long motelId;

    @Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;

    @Column(name = "room_number", nullable = false, length = 20)
    private String roomNumber;

    @Column(nullable = false)
    private Integer floor;

    @Column(precision = 10, scale = 2)
    private BigDecimal area;

    @Column(name = "base_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal basePrice;

    @Column(nullable = false, length = 20)
    private String status;

    @Column(name = "current_residents_count", nullable = false)
    private Integer currentResidentsCount = 0;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted;

    @Column
    private String description;
}

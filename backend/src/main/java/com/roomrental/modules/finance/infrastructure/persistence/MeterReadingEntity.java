package com.roomrental.modules.finance.infrastructure.persistence;

import com.roomrental.common.entity.BaseEntity;
import com.roomrental.modules.finance.domain.model.MeterReading.MeterReadingStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "meter_readings")
@Getter
@Setter
public class MeterReadingEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "service_usage_id", nullable = false)
    private Long serviceUsageId;

    @Column(name = "billing_month", nullable = false)
    private LocalDate billingMonth;

    @Column(name = "old_reading", nullable = false, precision = 12, scale = 2)
    private BigDecimal oldReading;

    @Column(name = "new_reading", nullable = false, precision = 12, scale = 2)
    private BigDecimal newReading;

    @Column(name = "consumption", nullable = false, precision = 12, scale = 2, insertable = false, updatable = false)
    private BigDecimal consumption;

    @Column(name = "reading_image_url", columnDefinition = "TEXT")
    private String readingImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private MeterReadingStatus status;

    @Column(name = "submitted_by")
    private UUID submittedBy;

    @Column(name = "approved_by")
    private UUID approvedBy;
}

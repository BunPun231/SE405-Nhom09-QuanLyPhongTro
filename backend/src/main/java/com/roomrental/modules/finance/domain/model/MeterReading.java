package com.roomrental.modules.finance.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

public class MeterReading {
    private Long id;
    private UUID tenantId;
    private Long roomId;
    private Long serviceUsageId;
    private LocalDate billingMonth;
    private BigDecimal oldReading;
    private BigDecimal newReading;
    private BigDecimal consumption;
    private String readingImageUrl;
    private MeterReadingStatus status;
    private UUID submittedBy;
    private UUID approvedBy;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public MeterReading() {
    }

    public enum MeterReadingStatus {
        PENDING, APPROVED, REJECTED
    }

    public void calculateConsumption() {
        if (oldReading != null && newReading != null) {
            this.consumption = newReading.subtract(oldReading);
        }
    }

    public boolean canBeApproved() {
        return this.status == MeterReadingStatus.PENDING;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public UUID getTenantId() { return tenantId; }
    public void setTenantId(UUID tenantId) { this.tenantId = tenantId; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getServiceUsageId() { return serviceUsageId; }
    public void setServiceUsageId(Long serviceUsageId) { this.serviceUsageId = serviceUsageId; }
    public LocalDate getBillingMonth() { return billingMonth; }
    public void setBillingMonth(LocalDate billingMonth) { this.billingMonth = billingMonth; }
    public BigDecimal getOldReading() { return oldReading; }
    public void setOldReading(BigDecimal oldReading) { this.oldReading = oldReading; }
    public BigDecimal getNewReading() { return newReading; }
    public void setNewReading(BigDecimal newReading) { this.newReading = newReading; }
    public BigDecimal getConsumption() { return consumption; }
    public void setConsumption(BigDecimal consumption) { this.consumption = consumption; }
    public String getReadingImageUrl() { return readingImageUrl; }
    public void setReadingImageUrl(String readingImageUrl) { this.readingImageUrl = readingImageUrl; }
    public MeterReadingStatus getStatus() { return status; }
    public void setStatus(MeterReadingStatus status) { this.status = status; }
    public UUID getSubmittedBy() { return submittedBy; }
    public void setSubmittedBy(UUID submittedBy) { this.submittedBy = submittedBy; }
    public UUID getApprovedBy() { return approvedBy; }
    public void setApprovedBy(UUID approvedBy) { this.approvedBy = approvedBy; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}


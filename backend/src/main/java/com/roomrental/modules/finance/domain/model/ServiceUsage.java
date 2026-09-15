package com.roomrental.modules.finance.domain.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class ServiceUsage {
    private Long id;
    private Long roomId;
    private Long serviceId;
    private Integer registeredQuantity;
    private BigDecimal startIndex;
    private ServiceUsageStatus status;
    private OffsetDateTime registeredAt;
    private OffsetDateTime updatedAt;

    public enum ServiceUsageStatus {
        ACTIVE, PENDING_CANCELLATION, CANCELLED
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public Long getServiceId() { return serviceId; }
    public void setServiceId(Long serviceId) { this.serviceId = serviceId; }
    public Integer getRegisteredQuantity() { return registeredQuantity; }
    public void setRegisteredQuantity(Integer registeredQuantity) { this.registeredQuantity = registeredQuantity; }
    public BigDecimal getStartIndex() { return startIndex; }
    public void setStartIndex(BigDecimal startIndex) { this.startIndex = startIndex; }
    public ServiceUsageStatus getStatus() { return status; }
    public void setStatus(ServiceUsageStatus status) { this.status = status; }
    public OffsetDateTime getRegisteredAt() { return registeredAt; }
    public void setRegisteredAt(OffsetDateTime registeredAt) { this.registeredAt = registeredAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
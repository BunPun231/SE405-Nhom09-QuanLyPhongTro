package com.roomrental.modules.finance.infrastructure.persistence;

import com.roomrental.modules.finance.domain.model.ServiceUsage.ServiceUsageStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "service_usages")
public class ServiceUsageEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "service_id", nullable = false)
    private Long serviceId;

    @Column(name = "registered_quantity", nullable = false)
    private Integer registeredQuantity;

    @Column(name = "start_index", precision = 12, scale = 2)
    private BigDecimal startIndex;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ServiceUsageStatus status;

    @Column(name = "registered_at", nullable = false)
    private OffsetDateTime registeredAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

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
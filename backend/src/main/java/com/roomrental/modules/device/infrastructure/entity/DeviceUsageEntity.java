package com.roomrental.modules.device.infrastructure.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "device_usages")
public class DeviceUsageEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "assigned_quantity", nullable = false)
    private Integer assignedQuantity = 1;

    @Column(name = "condition", nullable = false, length = 20)
    private String condition;

    @Column(name = "assigned_at", nullable = false, updatable = false)
    private OffsetDateTime assignedAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    public DeviceUsageEntity() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }

    public Integer getAssignedQuantity() { return assignedQuantity; }
    public void setAssignedQuantity(Integer assignedQuantity) { this.assignedQuantity = assignedQuantity; }

    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }

    public OffsetDateTime getAssignedAt() { return assignedAt; }
    public void setAssignedAt(OffsetDateTime assignedAt) { this.assignedAt = assignedAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}

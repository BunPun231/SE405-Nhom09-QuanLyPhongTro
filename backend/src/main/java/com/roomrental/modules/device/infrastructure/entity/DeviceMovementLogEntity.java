package com.roomrental.modules.device.infrastructure.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "device_movement_logs")
public class DeviceMovementLogEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_id", nullable = false)
    private Long deviceId;

    @Column(name = "from_room_id")
    private Long fromRoomId;

    @Column(name = "to_room_id")
    private Long toRoomId;

    @Column(name = "action", nullable = false, length = 20)
    private String action;

    @Column(name = "quantity", nullable = false)
    private Integer quantity = 1;

    @Column(name = "changed_by", nullable = false)
    private UUID changedBy;

    @Column(name = "timestamp", nullable = false, updatable = false)
    private OffsetDateTime timestamp = OffsetDateTime.now();

    @Column(name = "note")
    private String note;

    public DeviceMovementLogEntity() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }

    public Long getFromRoomId() { return fromRoomId; }
    public void setFromRoomId(Long fromRoomId) { this.fromRoomId = fromRoomId; }

    public Long getToRoomId() { return toRoomId; }
    public void setToRoomId(Long toRoomId) { this.toRoomId = toRoomId; }

    public Integer getQuantity() { return quantity != null ? quantity : 1; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public UUID getChangedBy() { return changedBy; }
    public void setChangedBy(UUID changedBy) { this.changedBy = changedBy; }

    public OffsetDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(OffsetDateTime timestamp) { this.timestamp = timestamp; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}

package com.roomrental.modules.room.domain.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Domain model for Room. Pure Java — synced with DB table "rooms".
 */
public class Room {

    private Long id;
    private Long version;
    private Long motelId;
    private String roomNumber;
    private Integer floor;
    private BigDecimal area;
    private BigDecimal basePrice;
    private RoomStatus status;
    private Integer currentResidentsCount;
    private boolean deleted;
    private String description;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    // ── Getters & Setters ────────────────────────────────────────────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }

    public Long getMotelId() { return motelId; }
    public void setMotelId(Long motelId) { this.motelId = motelId; }

    public String getRoomNumber() { return roomNumber; }
    public void setRoomNumber(String roomNumber) { this.roomNumber = roomNumber; }

    public Integer getFloor() { return floor; }
    public void setFloor(Integer floor) { this.floor = floor; }

    public BigDecimal getArea() { return area; }
    public void setArea(BigDecimal area) { this.area = area; }

    public BigDecimal getBasePrice() { return basePrice; }
    public void setBasePrice(BigDecimal basePrice) { this.basePrice = basePrice; }

    public RoomStatus getStatus() { return status; }
    public void setStatus(RoomStatus status) { this.status = status; }

    public Integer getCurrentResidentsCount() { return currentResidentsCount; }
    public void setCurrentResidentsCount(Integer currentResidentsCount) { this.currentResidentsCount = currentResidentsCount; }

    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}

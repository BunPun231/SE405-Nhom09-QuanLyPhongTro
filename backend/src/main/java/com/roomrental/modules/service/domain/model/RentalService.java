package com.roomrental.modules.service.domain.model;

import java.time.OffsetDateTime;

/**
 * Domain model for Service. Pure Java — synced with DB table "services".
 */
public class RentalService {

    private Long id;
    private Long motelId;
    private String name;
    private ChargeType chargeType;
    private String unit;
    private boolean mandatory;
    private boolean deleted;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getMotelId() { return motelId; }
    public void setMotelId(Long motelId) { this.motelId = motelId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public ChargeType getChargeType() { return chargeType; }
    public void setChargeType(ChargeType chargeType) { this.chargeType = chargeType; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public boolean isMandatory() { return mandatory; }
    public void setMandatory(boolean mandatory) { this.mandatory = mandatory; }

    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}

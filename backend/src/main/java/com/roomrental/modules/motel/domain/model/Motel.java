package com.roomrental.modules.motel.domain.model;

import java.time.OffsetDateTime;
import java.util.UUID;

public class Motel {
    private Long id;
    private UUID tenantId;
    private String name;
    private String address;
    private Integer totalFloors;
    private String description;
    private Integer billingCycleDay;
    private java.math.BigDecimal depositPercent;
    private String bankConfig;
    private boolean deleted;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(UUID tenantId) {
        this.tenantId = tenantId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public Integer getTotalFloors() {
        return totalFloors;
    }

    public void setTotalFloors(Integer totalFloors) {
        this.totalFloors = totalFloors;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getBillingCycleDay() {
        return billingCycleDay;
    }

    public void setBillingCycleDay(Integer billingCycleDay) {
        this.billingCycleDay = billingCycleDay;
    }

    public java.math.BigDecimal getDepositPercent() {
        return depositPercent;
    }

    public void setDepositPercent(java.math.BigDecimal depositPercent) {
        this.depositPercent = depositPercent;
    }

    public String getBankConfig() {
        return bankConfig;
    }

    public void setBankConfig(String bankConfig) {
        this.bankConfig = bankConfig;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}

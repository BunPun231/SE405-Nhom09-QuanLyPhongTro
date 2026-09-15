package com.roomrental.modules.contract.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Domain model cho Phụ lục hợp đồng (thay đổi giá điều chỉnh).
 */
public class ContractAppendix {
    private Long id;
    private java.util.UUID tenantId;
    private Long contractId;
    private LocalDate effectiveDate;
    private BigDecimal newRentPrice;
    private String appendixType;
    private String metadata;  // JSON payload
    private String newServicePrices; // JSON payload storing new service prices array
    private UUID createdBy;
    private LocalDateTime createdAt;

    // Constructors
    public ContractAppendix() {
    }

    public ContractAppendix(Long contractId, LocalDate effectiveDate, BigDecimal newRentPrice,
                           String appendixType, UUID createdBy) {
        this.contractId = contractId;
        this.effectiveDate = effectiveDate;
        this.newRentPrice = newRentPrice;
        this.appendixType = appendixType;
        this.createdBy = createdBy;
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public java.util.UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(java.util.UUID tenantId) {
        this.tenantId = tenantId;
    }

    public Long getContractId() {
        return contractId;
    }

    public void setContractId(Long contractId) {
        this.contractId = contractId;
    }

    public LocalDate getEffectiveDate() {
        return effectiveDate;
    }

    public void setEffectiveDate(LocalDate effectiveDate) {
        this.effectiveDate = effectiveDate;
    }

    public BigDecimal getNewRentPrice() {
        return newRentPrice;
    }

    public void setNewRentPrice(BigDecimal newRentPrice) {
        this.newRentPrice = newRentPrice;
    }

    public String getAppendixType() {
        return appendixType;
    }

    public void setAppendixType(String appendixType) {
        this.appendixType = appendixType;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public String getNewServicePrices() {
        return newServicePrices;
    }

    public void setNewServicePrices(String newServicePrices) {
        this.newServicePrices = newServicePrices;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(UUID createdBy) {
        this.createdBy = createdBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}

package com.roomrental.modules.contract.infrastructure.persistence;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * JPA Entity cho ContractAppendix (bảng contract_appendixes).
 */
@Entity
@Table(name = "contract_appendixes")
public class ContractAppendixEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "contract_id", nullable = false)
    private Long contractId;

    @Column(name = "effective_date", nullable = false)
    private LocalDate effectiveDate;

    @Column(name = "new_rent_price", precision = 12, scale = 2)
    private BigDecimal newRentPrice;

    @Column(name = "new_service_prices", columnDefinition = "jsonb")
    private String newServicePrices;

    @Column(name = "appendix_type", nullable = false)
    private String appendixType;

    @Column(name = "metadata", columnDefinition = "TEXT")
    private String metadata;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // Constructors
    public ContractAppendixEntity() {
    }

    public ContractAppendixEntity(UUID tenantId, Long contractId, LocalDate effectiveDate, String appendixType) {
        this.tenantId = tenantId;
        this.contractId = contractId;
        this.effectiveDate = effectiveDate;
        this.appendixType = appendixType;
        this.createdAt = LocalDateTime.now();
    }

    // Getters & Setters
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
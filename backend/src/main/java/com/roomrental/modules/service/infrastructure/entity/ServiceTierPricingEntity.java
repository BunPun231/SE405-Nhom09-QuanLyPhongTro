package com.roomrental.modules.service.infrastructure.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "service_tier_pricing")
public class ServiceTierPricingEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pricing_id", nullable = false)
    private Long pricingId;

    @Column(name = "tier_start", nullable = false, precision = 12, scale = 2)
    private BigDecimal tierStart;

    @Column(name = "tier_end", precision = 12, scale = 2)
    private BigDecimal tierEnd;

    @Column(name = "price_per_unit", nullable = false, precision = 12, scale = 2)
    private BigDecimal pricePerUnit;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getPricingId() { return pricingId; }
    public void setPricingId(Long pricingId) { this.pricingId = pricingId; }
    public BigDecimal getTierStart() { return tierStart; }
    public void setTierStart(BigDecimal tierStart) { this.tierStart = tierStart; }
    public BigDecimal getTierEnd() { return tierEnd; }
    public void setTierEnd(BigDecimal tierEnd) { this.tierEnd = tierEnd; }
    public BigDecimal getPricePerUnit() { return pricePerUnit; }
    public void setPricePerUnit(BigDecimal pricePerUnit) { this.pricePerUnit = pricePerUnit; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
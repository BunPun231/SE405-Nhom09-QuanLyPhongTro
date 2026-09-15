package com.roomrental.modules.service.domain.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class ServiceTierPricing {
    private Long id;
    private Long pricingId;
    private BigDecimal tierStart;
    private BigDecimal tierEnd;
    private BigDecimal pricePerUnit;
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
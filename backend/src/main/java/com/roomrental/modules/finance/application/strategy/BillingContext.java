package com.roomrental.modules.finance.application.strategy;

import java.math.BigDecimal;
import java.util.List;

public record BillingContext(
    Long serviceId,
    String serviceName,
    String chargeType,
    BigDecimal oldReading,
    BigDecimal newReading,
    BigDecimal quantity,
    Integer activeResidents,
    BigDecimal basePrice,
    List<PricingTier> pricingTiers
) {
    public record PricingTier(
        BigDecimal tierStart,
        BigDecimal tierEnd,
        BigDecimal pricePerUnit
    ) {}
}

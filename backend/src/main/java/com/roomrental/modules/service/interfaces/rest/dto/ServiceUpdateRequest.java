package com.roomrental.modules.service.interfaces.rest.dto;

import java.math.BigDecimal;
import java.util.List;

public record ServiceUpdateRequest(
        String name,
        String chargeType,
        String unit,
        Boolean mandatory,
        BigDecimal basePrice,
        List<ServiceTierPricingRequest> pricingTiers
) {
}

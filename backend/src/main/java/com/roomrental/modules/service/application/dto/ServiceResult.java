package com.roomrental.modules.service.application.dto;

import java.math.BigDecimal;
import java.util.List;

public record ServiceResult(
        Long id,
        Long motelId,
        String name,
        String chargeType,
        String unit,
        boolean mandatory,
        BigDecimal basePrice,
        List<ServiceTierPricingResult> pricingTiers
) {
}

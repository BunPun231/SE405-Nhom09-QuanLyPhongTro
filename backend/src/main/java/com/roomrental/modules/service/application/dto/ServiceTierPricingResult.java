package com.roomrental.modules.service.application.dto;

import java.math.BigDecimal;

public record ServiceTierPricingResult(
        BigDecimal tierStart,
        BigDecimal tierEnd,
        BigDecimal pricePerUnit
) {
}
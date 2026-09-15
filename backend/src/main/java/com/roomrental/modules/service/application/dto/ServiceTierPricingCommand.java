package com.roomrental.modules.service.application.dto;

import java.math.BigDecimal;

public record ServiceTierPricingCommand(
        BigDecimal tierStart,
        BigDecimal tierEnd,
        BigDecimal pricePerUnit
) {
}
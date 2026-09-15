package com.roomrental.modules.service.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ServiceTierPricingRequest(
        @NotNull BigDecimal tierStart,
        BigDecimal tierEnd,
        @NotNull BigDecimal pricePerUnit
) {
}
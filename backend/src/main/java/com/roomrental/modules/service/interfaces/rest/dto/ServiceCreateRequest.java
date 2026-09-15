package com.roomrental.modules.service.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;

public record ServiceCreateRequest(
        @NotBlank(message = "Service name is required")
        String name,

        @NotBlank(message = "Charge type is required")
        String chargeType,

        String unit,
        Boolean mandatory,
        @NotNull(message = "basePrice is required")
        BigDecimal basePrice,
        List<ServiceTierPricingRequest> pricingTiers
) {
}

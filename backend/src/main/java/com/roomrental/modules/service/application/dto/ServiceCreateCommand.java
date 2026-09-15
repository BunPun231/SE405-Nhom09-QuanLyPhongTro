package com.roomrental.modules.service.application.dto;

import java.math.BigDecimal;
import java.util.List;

public record ServiceCreateCommand(
        String name,
        String chargeType,
        String unit,
        Boolean mandatory,
        BigDecimal basePrice,
        List<ServiceTierPricingCommand> pricingTiers
) {
}

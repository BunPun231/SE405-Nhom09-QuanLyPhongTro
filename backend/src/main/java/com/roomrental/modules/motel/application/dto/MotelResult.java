package com.roomrental.modules.motel.application.dto;

public record MotelResult(
        Long id,
        String tenantId,
        String name,
        String address,
        Integer totalFloors,
        String description,
        Integer billingCycleDay,
        java.math.BigDecimal depositPercent,
        String bankConfig
) {
}

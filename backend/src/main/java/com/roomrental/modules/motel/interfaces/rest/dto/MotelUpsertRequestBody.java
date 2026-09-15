package com.roomrental.modules.motel.interfaces.rest.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record MotelUpsertRequestBody(
        @NotBlank String name,
        @NotBlank String address,
        @NotNull @Min(1) Integer totalFloors,
        String description,
        Integer billingCycleDay,
        java.math.BigDecimal depositPercent,
        String bankConfig
) {
}

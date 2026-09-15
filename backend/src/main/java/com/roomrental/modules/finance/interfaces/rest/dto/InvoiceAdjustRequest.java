package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.util.Map;

public record InvoiceAdjustRequest(
    @NotBlank String reason,
    Map<Long, BigDecimal> correctedReadings,
    Map<Long, BigDecimal> customAdjustments
) {}

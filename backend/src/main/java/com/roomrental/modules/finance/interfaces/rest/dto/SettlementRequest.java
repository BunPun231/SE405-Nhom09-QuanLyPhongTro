package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;

public record SettlementRequest(
    @NotNull Long contractId,
    @NotNull java.time.LocalDate moveOutDate,
    BigDecimal finalElectricReading,
    BigDecimal finalWaterReading,
    List<com.roomrental.modules.finance.application.dto.DamageItemInput> damages
) {}

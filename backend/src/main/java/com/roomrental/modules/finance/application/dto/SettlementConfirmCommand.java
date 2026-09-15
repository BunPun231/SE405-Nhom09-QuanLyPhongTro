package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

import java.util.List;

public record SettlementConfirmCommand(
    Long contractId,
    java.time.LocalDate moveOutDate,
    BigDecimal finalElectricReading,
    BigDecimal finalWaterReading,
    List<DamageItemInput> damages
) {}

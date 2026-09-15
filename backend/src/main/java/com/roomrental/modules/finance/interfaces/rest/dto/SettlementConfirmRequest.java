package com.roomrental.modules.finance.interfaces.rest.dto;

import java.math.BigDecimal;

import java.util.List;

public record SettlementConfirmRequest(
    java.time.LocalDate moveOutDate,
    BigDecimal finalElectricReading,
    BigDecimal finalWaterReading,
    List<com.roomrental.modules.finance.application.dto.DamageItemInput> damages
) {}

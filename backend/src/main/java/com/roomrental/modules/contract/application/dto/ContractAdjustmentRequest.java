package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Command DTO for contract adjustments (UC66).
 */
public record ContractAdjustmentRequest(
        String type,
        LocalDate effectiveDate,
        BigDecimal newRentPrice,
        LocalDate newEndDate,
        LocalDate intendedMoveOutDate,
        String metadata,
        boolean applyToCurrentContracts,
        String newServicePrices
) {
}

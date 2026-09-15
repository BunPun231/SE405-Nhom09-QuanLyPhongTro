package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Result DTO for contract appendix.
 */
public record ContractAppendixResult(
        Long id,
        Long contractId,
        LocalDate effectiveDate,
        BigDecimal newRentPrice,
        String appendixType,
        String metadata,
        String newServicePrices,
        String createdBy,
        LocalDateTime createdAt
) {
}

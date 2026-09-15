package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Result DTO cho Contract (response).
 */
public record ContractResult(
        Long id,
        String tenantId,
        Long roomId,
        String primaryResidentUserId,
        BigDecimal rentPrice,
        LocalDate startDate,
        LocalDate endDate,
        BigDecimal depositAmount,
        String depositStatus,
        String status,
        LocalDate billingDate,
        Integer billingCycleDay,
        Integer paymentCycleMonths,
        LocalDate intendedMoveOutDate,
        String pdfUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}

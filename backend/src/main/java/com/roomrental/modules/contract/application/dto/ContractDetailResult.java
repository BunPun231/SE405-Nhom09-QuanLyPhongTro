package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Detailed contract result for UC65.
 * Only returns appendices count — full appendix data is fetched via separate endpoints.
 */
public record ContractDetailResult(
        Long id,
        String tenantId,
        Long roomId,
        Long motelId,
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
        LocalDateTime updatedAt,
        List<String> residentUserIds,
        List<ContractServiceItemResult> serviceItems,
        int appendicesCount
) {
}

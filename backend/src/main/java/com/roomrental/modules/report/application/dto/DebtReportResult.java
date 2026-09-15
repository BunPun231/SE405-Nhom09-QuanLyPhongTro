package com.roomrental.modules.report.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * UC92: Debt report response.
 */
public record DebtReportResult(
        Long motelId,
        BigDecimal totalDebt,
        Integer debtorCount,
        List<DebtEntry> entries
) {
    public record DebtEntry(
            Long invoiceId,
            Long roomId,
            String roomNumber,
            String residentName,
            String residentPhone,
            LocalDate billingMonth,
            BigDecimal totalAmount,
            BigDecimal paidAmount,
            BigDecimal debtAmount,   // totalAmount - paidAmount
            LocalDate dueDate,
            Integer daysOverdue,     // Max(0, today - dueDate)
            String agingBucket       // "NEW" (<7d), "OVERDUE" (7-30d), "BAD_DEBT" (>30d)
    ) {}
}

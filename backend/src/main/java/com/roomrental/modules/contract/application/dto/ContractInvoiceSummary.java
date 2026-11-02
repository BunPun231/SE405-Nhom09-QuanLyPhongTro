package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * UC65: Hoa don lien quan den hop dong (lich su thanh toan).
 */
public record ContractInvoiceSummary(
        Long id,
        LocalDate billingMonth,
        String invoiceType,
        String status,
        BigDecimal totalAmount,
        BigDecimal paidAmount,
        BigDecimal balanceDeduction,
        BigDecimal remainingAmount,
        LocalDate dueDate
) {
}

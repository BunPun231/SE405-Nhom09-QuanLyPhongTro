package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

public record InvoiceResult(
    Long id,
    Long contractId,
    Long roomId,
    String roomNumber,
    LocalDate billingMonth,
    BigDecimal totalAmount,
    BigDecimal paidAmount,
    BigDecimal balanceDeduction,
    BigDecimal remainingAmount,
    BigDecimal overpaidAmount,
    BigDecimal creditBalanceSnapshot,
    String calculationSnapshot,
    String status,
    String invoiceType,
    String cancelReason,
    LocalDate dueDate,
    OffsetDateTime createdAt,
    List<InvoiceDetailResult> details
) {}

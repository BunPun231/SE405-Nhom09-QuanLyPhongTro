package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

/**
 * Trang thai tat toan cua mot hop dong (UC80).
 * settlementInvoiceId == null nghia la hop dong chua duoc tat toan.
 */
public record SettlementStatusResult(
    Long contractId,
    String contractStatus,
    String depositStatus,
    String roomStatus,
    Long settlementInvoiceId,
    String settlementInvoiceStatus,
    BigDecimal settlementTotal,
    BigDecimal depositDeducted,
    BigDecimal paidAmount,
    BigDecimal remainingAmount,
    BigDecimal repairFees
) {}

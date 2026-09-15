package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;
import java.util.List;

public record SettlementConfirmationResult(
    Long contractId,
    String contractStatus,
    Long roomId,
    String roomStatus,
    BigDecimal depositSnapshot,
    BigDecimal oldDebtDeducted,
    BigDecimal settlementDeducted,
    BigDecimal netAmount,
    InvoiceResult settlementInvoice,
    List<InvoiceDetailResult> settlementInvoiceDetails,
    TransactionResult refundTransaction
) {}
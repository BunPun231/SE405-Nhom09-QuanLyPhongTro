package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

public record SettlementResult(
    Long contractId,
    BigDecimal deposit,
    BigDecimal currentDebt,
    BigDecimal proRatedRent,
    BigDecimal finalUtilities,
    BigDecimal repairFees,
    BigDecimal netAmount,
    Long settlementInvoiceId
) {}

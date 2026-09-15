package com.roomrental.modules.finance.interfaces.rest.dto;

import java.math.BigDecimal;

public record InvoicePaymentInfoResult(
        String bankId,
        String bankAccount,
        String accountHolder,
        String bankName,
        BigDecimal amount,
        String memo,
        String qrUrl
) {}

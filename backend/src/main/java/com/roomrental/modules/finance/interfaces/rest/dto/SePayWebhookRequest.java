package com.roomrental.modules.finance.interfaces.rest.dto;

import java.math.BigDecimal;

public record SePayWebhookRequest(
        Long id,
        String gateway,
        String transactionDate,
        String accountNumber,
        String code,
        String content,
        String transferType,
        BigDecimal transferAmount,
        BigDecimal accumulated,
        String subAccount,
        String referenceCode
) {}

package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

public record PaymentWebhookCommand(
    String transactionRef,
    BigDecimal amount,
    String bankCode,
    String memo,
    String rawData
) {}

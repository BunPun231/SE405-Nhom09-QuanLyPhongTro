package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

public record PaymentManualCommand(
    Long invoiceId,
    BigDecimal amount,
    String paymentMethod
) {}

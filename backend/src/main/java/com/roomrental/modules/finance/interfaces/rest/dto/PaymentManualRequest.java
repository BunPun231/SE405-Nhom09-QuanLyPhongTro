package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record PaymentManualRequest(
    @NotNull Long invoiceId,
    @NotNull BigDecimal amount,
    @NotBlank String paymentMethod
) {}

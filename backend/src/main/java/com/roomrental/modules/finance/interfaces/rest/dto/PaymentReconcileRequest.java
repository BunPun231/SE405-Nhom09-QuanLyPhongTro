package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;

public record PaymentReconcileRequest(
    @NotNull Long transactionId,
    @NotNull Long invoiceId
) {}

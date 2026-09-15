package com.roomrental.modules.finance.application.dto;

public record PaymentReconcileCommand(
    Long transactionId,
    Long invoiceId
) {}

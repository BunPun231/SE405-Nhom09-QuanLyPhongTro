package com.roomrental.modules.finance.application.dto;

import java.time.LocalDate;

public record InvoiceGenerateCommand(
    Long motelId,
    LocalDate billingMonth
) {}

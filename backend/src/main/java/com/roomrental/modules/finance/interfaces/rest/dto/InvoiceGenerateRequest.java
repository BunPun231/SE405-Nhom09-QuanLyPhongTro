package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record InvoiceGenerateRequest(
    @NotNull Long motelId,
    @NotNull LocalDate billingMonth
) {}

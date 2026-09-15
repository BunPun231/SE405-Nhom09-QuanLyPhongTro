package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;

public record MeterReadingRequest(
    @NotNull Long roomId,
    @NotNull Long serviceId,
    @NotNull LocalDate billingMonth,
    @NotNull BigDecimal newReading,
    String readingImageUrl
) {}

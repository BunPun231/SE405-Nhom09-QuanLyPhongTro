package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record MeterReadingSubmitCommand(
    Long roomId,
    Long serviceId,
    LocalDate billingMonth,
    BigDecimal newReading,
    String readingImageUrl
) {}

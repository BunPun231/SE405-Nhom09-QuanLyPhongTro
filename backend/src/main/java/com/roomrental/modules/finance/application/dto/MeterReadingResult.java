package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

public record MeterReadingResult(
    Long id,
    Long roomId,
    Long serviceId,
    String serviceName,
    LocalDate billingMonth,
    BigDecimal oldReading,
    BigDecimal newReading,
    BigDecimal consumption,
    String status,
    String readingImageUrl,
    Double ocrConfidence,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt
) {}


package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * UC70 submit request. The meter photo (BR01 evidence) can be sent either as an
 * already-hosted {@code readingImageUrl} or as {@code base64Image} + {@code mimeType},
 * in which case the backend uploads it to private storage before saving.
 */
public record MeterReadingRequest(
    @NotNull Long roomId,
    @NotNull Long serviceId,
    @NotNull LocalDate billingMonth,
    @NotNull BigDecimal newReading,
    String readingImageUrl,
    String base64Image,
    String mimeType
) {}

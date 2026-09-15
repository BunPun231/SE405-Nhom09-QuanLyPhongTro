package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record MeterReadingOcrRequest(
    @NotNull Long roomId,
    @NotNull Long serviceId,
    @NotNull LocalDate billingMonth,
    @NotNull String base64Image,
    @NotNull String mimeType
) {}

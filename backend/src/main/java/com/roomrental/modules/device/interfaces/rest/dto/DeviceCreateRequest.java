package com.roomrental.modules.device.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.time.LocalDate;

public record DeviceCreateRequest(
        @NotBlank(message = "Device name is required")
        String name,
        String brand,
        BigDecimal purchasePrice,
        LocalDate purchaseDate
) {
}

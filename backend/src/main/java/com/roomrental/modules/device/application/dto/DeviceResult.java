package com.roomrental.modules.device.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DeviceResult(
        Long id, Long motelId, String name, String brand,
        BigDecimal purchasePrice, LocalDate purchaseDate, String status
) {
}

package com.roomrental.modules.device.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DeviceUpdateCommand(
        String name, String brand, BigDecimal purchasePrice, LocalDate purchaseDate, String status
) {
}

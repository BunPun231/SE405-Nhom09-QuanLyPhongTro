package com.roomrental.modules.device.interfaces.rest.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DeviceUpdateRequest(
        String name, String brand, BigDecimal purchasePrice, LocalDate purchaseDate, String status
) {
}

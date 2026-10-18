package com.roomrental.modules.device.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record DeviceCreateCommand(
        String name, String brand, BigDecimal purchasePrice, LocalDate purchaseDate, Integer totalQuantity
) {
    public DeviceCreateCommand(String name, String brand, BigDecimal purchasePrice, LocalDate purchaseDate) {
        this(name, brand, purchasePrice, purchaseDate, 1);
    }
}



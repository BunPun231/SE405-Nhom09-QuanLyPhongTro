package com.roomrental.modules.room.application.dto;

import java.math.BigDecimal;

public record RoomUpdateCommand(
        String roomNumber,
        Integer floor,
        BigDecimal area,
        BigDecimal basePrice,
        String status,
        String description
) {
}

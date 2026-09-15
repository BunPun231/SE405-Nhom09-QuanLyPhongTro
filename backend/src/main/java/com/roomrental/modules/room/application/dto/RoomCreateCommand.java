package com.roomrental.modules.room.application.dto;

import java.math.BigDecimal;

public record RoomCreateCommand(
        String roomNumber,
        Integer floor,
        BigDecimal area,
        BigDecimal basePrice,
        String description
) {
}

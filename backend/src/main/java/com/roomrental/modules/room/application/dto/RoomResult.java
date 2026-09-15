package com.roomrental.modules.room.application.dto;

import java.math.BigDecimal;

public record RoomResult(
        Long id,
        Long motelId,
        String roomNumber,
        Integer floor,
        BigDecimal area,
        BigDecimal basePrice,
        String status,
        Integer currentResidentsCount,
        String description,
        String hashid
) {
}

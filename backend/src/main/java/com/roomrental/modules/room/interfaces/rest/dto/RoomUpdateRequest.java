package com.roomrental.modules.room.interfaces.rest.dto;

import java.math.BigDecimal;

public record RoomUpdateRequest(
        String roomNumber,
        Integer floor,
        BigDecimal area,
        BigDecimal basePrice,
        String description
) {
}

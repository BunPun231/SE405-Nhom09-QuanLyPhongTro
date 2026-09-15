package com.roomrental.modules.service.application.dto;

import java.util.List;
import java.math.BigDecimal;

public record ServiceAssignCommand(
    List<RoomAssignInput> rooms
) {
    public record RoomAssignInput(Long roomId, Integer quantity, BigDecimal startIndex) {}
}

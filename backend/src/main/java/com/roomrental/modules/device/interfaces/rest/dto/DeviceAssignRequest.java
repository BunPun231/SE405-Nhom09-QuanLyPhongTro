package com.roomrental.modules.device.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;

public record DeviceAssignRequest(
        @NotNull(message = "Room ID is required") Long roomId,
        Integer assignedQuantity,
        String condition,
        String note
) {}

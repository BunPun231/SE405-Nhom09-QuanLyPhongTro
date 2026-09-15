package com.roomrental.modules.room.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record RoomStatusRequest(
        @NotBlank(message = "Status is required")
        String status
) {
}

package com.roomrental.modules.maintenance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;

public record CreateTicketRequest(
        @NotNull(message = "Room ID is required") Long roomId,
        String category,
        @NotNull(message = "Description is required") String description,
        String priority
) {}

package com.roomrental.modules.room.interfaces.rest.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public record RoomCreateRequest(
        @NotBlank(message = "Room number is required")
        String roomNumber,

        @NotNull(message = "Floor is required")
        @Min(value = 1, message = "Floor must be at least 1")
        Integer floor,

        @DecimalMin(value = "0.01", message = "Area must be positive")
        BigDecimal area,

        @NotNull(message = "Base price is required")
        @DecimalMin(value = "0", message = "Base price must be non-negative")
        BigDecimal basePrice,

        String description
) {
}

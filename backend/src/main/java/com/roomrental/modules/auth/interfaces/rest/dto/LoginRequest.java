package com.roomrental.modules.auth.interfaces.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

/**
 * Request body for user login (UC02).
 * Identity can be either phone number or email.
 */
public record LoginRequest(
        @NotBlank(message = "Phone or email is required")
        @Schema(defaultValue = "0900000000")
        String identity,

        @NotBlank(message = "Password is required")
        @Schema(defaultValue = "Admin@1234")
        String password
) {
}

package com.roomrental.modules.auth.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Request body for manager registration (UC01).
 */
public record RegisterRequest(
        @NotBlank(message = "Tenant name is required")
        String tenantName,

        @NotBlank(message = "Full name is required")
        String fullName,

        @NotBlank(message = "Phone number is required")
        @Pattern(regexp = "^(84|0)(3|5|7|8|9)[0-9]{8}$", message = "Invalid Vietnamese phone number format")
        String phone,

        @Email(message = "Invalid email format")
        String email,

        @NotBlank(message = "Password is required")
        @Size(min = 8, max = 64, message = "Password must be between 8 and 64 characters")
        String password
) {
}

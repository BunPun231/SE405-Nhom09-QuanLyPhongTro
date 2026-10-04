package com.roomrental.modules.auth.interfaces.rest.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record UpdateProfileRequest(
        @NotBlank(message = "Full name is required")
        String fullName,

        @Email(message = "Invalid email format")
        String email,

        @Pattern(regexp = "^[0-9]{10,11}$", message = "Invalid phone number format")
        String phone,

        String avatarUrl
) {}

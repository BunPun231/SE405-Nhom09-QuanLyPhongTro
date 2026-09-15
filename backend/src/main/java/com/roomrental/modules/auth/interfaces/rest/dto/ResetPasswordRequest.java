package com.roomrental.modules.auth.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ResetPasswordRequest(
    @NotBlank(message = "Identity is required")
    String identity,

    @NotBlank(message = "OTP is required")
    String otp,

    @NotBlank(message = "New password is required")
    @Size(min = 8, message = "New password must be at least 8 characters long")
    String newPassword,

    @NotBlank(message = "Confirm password is required")
    String confirmPassword
) {}

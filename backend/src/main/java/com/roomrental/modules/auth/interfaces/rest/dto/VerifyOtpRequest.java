package com.roomrental.modules.auth.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record VerifyOtpRequest(
        @NotBlank(message = "Identity is required")
        String identity,

        @NotBlank(message = "OTP is required")
        String otp
) {}

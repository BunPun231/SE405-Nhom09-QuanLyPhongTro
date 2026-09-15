package com.roomrental.modules.auth.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record ForgotPasswordRequest(
    @NotBlank(message = "Identity (email/phone) is required")
    String identity
) {}

package com.roomrental.modules.auth.application.dto;

public record ResetPasswordCommand(
    String identity,
    String otp,
    String newPassword,
    String confirmPassword
) {}

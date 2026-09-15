package com.roomrental.modules.auth.application.dto;

public record ChangePasswordCommand(
    String oldPassword,
    String newPassword,
    String confirmPassword
) {}

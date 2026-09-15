package com.roomrental.modules.auth.application.dto;

public record ForgotPasswordCommand(
    String identity // phone or email
) {}

package com.roomrental.modules.auth.application.dto;

/**
 * Command for manager self-registration (UC01).
 */
public record RegisterCommand(
        String tenantName,
        String fullName,
        String phone,
        String email,
        String password
) {
}

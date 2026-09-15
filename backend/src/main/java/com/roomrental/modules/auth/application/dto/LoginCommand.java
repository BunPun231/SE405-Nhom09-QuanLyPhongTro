package com.roomrental.modules.auth.application.dto;

/**
 * Command for user login (UC02).
 * Supports login by phone or email (identity field).
 */
public record LoginCommand(
        String identity,
        String password
) {
}

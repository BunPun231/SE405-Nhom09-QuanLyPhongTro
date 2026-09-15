package com.roomrental.modules.auth.application.dto;

import java.util.UUID;

/**
 * Result returned after successful authentication.
 */
public record AuthResult(
        String accessToken,
        String refreshToken,
        String tokenType,
        UUID userId,
        UUID tenantId,
        String role,
        String fullName,
        boolean hasCompletedOnboarding
) {
}

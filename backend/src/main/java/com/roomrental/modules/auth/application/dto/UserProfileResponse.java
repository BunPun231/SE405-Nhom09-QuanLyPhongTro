package com.roomrental.modules.auth.application.dto;

import com.roomrental.modules.auth.domain.model.UserRole;
import com.roomrental.modules.auth.domain.model.UserStatus;

import java.time.OffsetDateTime;
import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        UUID tenantId,
        String phone,
        String email,
        String fullName,
        String avatarUrl,
        UserRole role,
        UserStatus status,
        boolean mustChangePassword,
        boolean hasCompletedOnboarding,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        OffsetDateTime lastLoginAt
) {}

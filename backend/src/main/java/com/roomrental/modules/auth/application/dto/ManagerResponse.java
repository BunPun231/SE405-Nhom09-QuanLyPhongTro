package com.roomrental.modules.auth.application.dto;

import com.roomrental.modules.auth.domain.model.UserStatus;

import java.time.OffsetDateTime;
import java.util.UUID;

public record ManagerResponse(
        UUID id,
        UUID tenantId,
        String tenantName,
        String phone,
        String email,
        String fullName,
        String avatarUrl,
        UserStatus status,
        String lockReason,
        OffsetDateTime createdAt,
        OffsetDateTime lastLoginAt
) {}

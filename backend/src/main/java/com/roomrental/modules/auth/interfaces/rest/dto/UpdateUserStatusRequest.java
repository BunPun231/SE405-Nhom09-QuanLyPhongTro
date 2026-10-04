package com.roomrental.modules.auth.interfaces.rest.dto;

import com.roomrental.modules.auth.domain.model.UserStatus;
import jakarta.validation.constraints.NotNull;

public record UpdateUserStatusRequest(
        @NotNull(message = "Status is required")
        UserStatus status,

        String lockReason
) {}

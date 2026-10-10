package com.roomrental.modules.device.application.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record DeviceMovementLogResult(
        Long id,
        Long deviceId,
        Long fromRoomId,
        Long toRoomId,
        String action,
        UUID changedBy,
        OffsetDateTime timestamp,
        String note
) {}

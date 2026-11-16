package com.roomrental.modules.device.application.dto;

import java.time.OffsetDateTime;

public record DeviceUsageResult(
        Long id,
        Long deviceId,
        String deviceName,
        String brand,
        Long roomId,
        String roomNumber,
        Integer assignedQuantity,
        String condition,
        OffsetDateTime assignedAt,
        OffsetDateTime updatedAt
) {}

package com.roomrental.modules.device.application.dto;

public record DeviceDisposeCommand(
        Integer quantity,
        String reason
) {}

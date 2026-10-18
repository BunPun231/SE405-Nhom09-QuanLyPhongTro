package com.roomrental.modules.device.application.dto;

public record DeviceFinishRepairCommand(
        Integer quantity,
        String note
) {}

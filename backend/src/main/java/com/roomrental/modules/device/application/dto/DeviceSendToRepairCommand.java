package com.roomrental.modules.device.application.dto;

public record DeviceSendToRepairCommand(
        Integer quantity,
        String note
) {}

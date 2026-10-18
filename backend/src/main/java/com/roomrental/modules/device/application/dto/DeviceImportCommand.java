package com.roomrental.modules.device.application.dto;

public record DeviceImportCommand(
        Integer quantity,
        String note
) {}

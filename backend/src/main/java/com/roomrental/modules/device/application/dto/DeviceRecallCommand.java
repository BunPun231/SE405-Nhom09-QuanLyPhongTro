package com.roomrental.modules.device.application.dto;

public record DeviceRecallCommand(
        Integer quantity,
        String note
) {
    public DeviceRecallCommand(String note) {
        this(null, note);
    }
}

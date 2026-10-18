package com.roomrental.modules.device.interfaces.rest.dto;

public record DeviceRecallRequest(
        Integer quantity,
        String note
) {
    public DeviceRecallRequest(String note) {
        this(null, note);
    }
}

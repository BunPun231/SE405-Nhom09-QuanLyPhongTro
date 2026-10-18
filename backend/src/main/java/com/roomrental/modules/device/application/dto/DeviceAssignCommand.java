package com.roomrental.modules.device.application.dto;

public record DeviceAssignCommand(
        Long roomId,
        Integer assignedQuantity,
        String condition,
        String note
) {
    public DeviceAssignCommand(Long roomId, Integer assignedQuantity, String note) {
        this(roomId, assignedQuantity, "GOOD", note);
    }

    public DeviceAssignCommand(Long roomId, Integer assignedQuantity) {
        this(roomId, assignedQuantity, "GOOD", null);
    }
}

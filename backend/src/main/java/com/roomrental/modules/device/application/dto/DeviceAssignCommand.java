package com.roomrental.modules.device.application.dto;

public record DeviceAssignCommand(
        Long roomId,
        Integer assignedQuantity,
        String condition,
        String note
) {}

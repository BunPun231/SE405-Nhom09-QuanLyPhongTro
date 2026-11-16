package com.roomrental.modules.device.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record DeviceDeletedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long deviceId, String deviceName, String brand
) implements LoggableEvent {
    @Override public String action() { return "DELETE_DEVICE"; }
    @Override public String entityType() { return "Device"; }
    @Override public String entityId() { return deviceId.toString(); }
    @Override public String oldValue() {
        return DeviceCreatedEvent.formatDeviceLabel(deviceName, brand, deviceId);
    }
    @Override public String newValue() { return "DELETED"; }
}

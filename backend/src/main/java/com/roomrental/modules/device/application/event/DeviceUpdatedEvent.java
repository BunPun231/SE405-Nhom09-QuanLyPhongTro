package com.roomrental.modules.device.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record DeviceUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long deviceId, String oldName, String newName
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_DEVICE"; }
    @Override public String entityType() { return "Device"; }
    @Override public String entityId() { return deviceId.toString(); }
    @Override public String oldValue() { return oldName; }
    @Override public String newValue() { return newName; }
}

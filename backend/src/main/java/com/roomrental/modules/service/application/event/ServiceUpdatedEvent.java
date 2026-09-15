package com.roomrental.modules.service.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ServiceUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long serviceId, String oldName, String newName
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_SERVICE"; }
    @Override public String entityType() { return "RentalService"; }
    @Override public String entityId() { return serviceId.toString(); }
    @Override public String oldValue() { return oldName; }
    @Override public String newValue() { return newName; }
}

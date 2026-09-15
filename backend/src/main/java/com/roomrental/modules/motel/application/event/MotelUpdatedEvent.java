package com.roomrental.modules.motel.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record MotelUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long motelId, String oldName, String newName
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_MOTEL"; }
    @Override public String entityType() { return "Motel"; }
    @Override public String entityId() { return motelId.toString(); }
    @Override public String oldValue() { return oldName; }
    @Override public String newValue() { return newName; }
}

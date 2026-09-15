package com.roomrental.modules.resident.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ResidentDeactivatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID residentId, String oldStatus
) implements LoggableEvent {
    @Override public String action() { return "DEACTIVATE_RESIDENT"; }
    @Override public String entityType() { return "Resident"; }
    @Override public String entityId() { return residentId.toString(); }
    @Override public String oldValue() { return oldStatus; }
    @Override public String newValue() { return "INACTIVE"; }
}

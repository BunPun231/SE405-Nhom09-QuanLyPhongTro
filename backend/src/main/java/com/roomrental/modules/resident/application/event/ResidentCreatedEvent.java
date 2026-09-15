package com.roomrental.modules.resident.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ResidentCreatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID residentId, String fullName
) implements LoggableEvent {
    @Override public String action() { return "CREATE_RESIDENT"; }
    @Override public String entityType() { return "Resident"; }
    @Override public String entityId() { return residentId.toString(); }
    @Override public String newValue() { return fullName; }
}

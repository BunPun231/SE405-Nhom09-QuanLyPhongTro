package com.roomrental.modules.resident.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ResidentReactivatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID residentId
) implements LoggableEvent {
    @Override public String action() { return "REACTIVATE_RESIDENT"; }
    @Override public String entityType() { return "Resident"; }
    @Override public String entityId() { return residentId.toString(); }
    @Override public String oldValue() { return "INACTIVE"; }
    @Override public String newValue() { return "ACTIVE"; }
}

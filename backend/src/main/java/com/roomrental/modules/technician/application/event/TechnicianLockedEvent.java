package com.roomrental.modules.technician.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record TechnicianLockedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID techId, String oldStatus, String reason
) implements LoggableEvent {
    @Override public String action() { return "LOCK_TECHNICIAN"; }
    @Override public String entityType() { return "Technician"; }
    @Override public String entityId() { return techId.toString(); }
    @Override public String oldValue() { return oldStatus; }
    @Override public String newValue() { return "LOCKED"; }
    @Override public String metadata() { return reason; }
}

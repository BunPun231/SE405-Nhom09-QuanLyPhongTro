package com.roomrental.modules.technician.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record TechnicianCreatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID techId, String fullName
) implements LoggableEvent {
    @Override public String action() { return "CREATE_TECHNICIAN"; }
    @Override public String entityType() { return "Technician"; }
    @Override public String entityId() { return techId.toString(); }
    @Override public String newValue() { return fullName; }
}

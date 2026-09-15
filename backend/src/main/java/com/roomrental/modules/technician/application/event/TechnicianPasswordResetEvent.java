package com.roomrental.modules.technician.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record TechnicianPasswordResetEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID techId
) implements LoggableEvent {
    @Override public String action() { return "RESET_TECHNICIAN_PASSWORD"; }
    @Override public String entityType() { return "Technician"; }
    @Override public String entityId() { return techId.toString(); }
    @Override public String newValue() { return "PASSWORD_RESET"; }
}

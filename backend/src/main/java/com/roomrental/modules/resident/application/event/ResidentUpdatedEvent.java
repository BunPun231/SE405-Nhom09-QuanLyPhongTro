package com.roomrental.modules.resident.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

/**
 * UC53 (Audit: log all changes / BR53.6): one event per changed field,
 * holding the field name in metadata and old/new values.
 * Sensitive values (CCCD, images) are masked before being logged.
 */
public record ResidentUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID residentId, String field, String oldVal, String newVal
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_RESIDENT"; }
    @Override public String entityType() { return "Resident"; }
    @Override public String entityId() { return residentId.toString(); }
    @Override public String oldValue() { return oldVal; }
    @Override public String newValue() { return newVal; }
    @Override public String metadata() { return "{\"field\":\"" + field + "\"}"; }
}

package com.roomrental.modules.motel.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record MotelDeletedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long motelId, String motelName
) implements LoggableEvent {
    @Override public String action() { return "DELETE_MOTEL"; }
    @Override public String entityType() { return "Motel"; }
    @Override public String entityId() { return motelId.toString(); }
    @Override public String oldValue() { return motelName; }
    @Override public String newValue() { return "DELETED"; }
}

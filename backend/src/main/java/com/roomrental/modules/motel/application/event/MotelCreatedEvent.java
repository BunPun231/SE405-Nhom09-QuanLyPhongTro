package com.roomrental.modules.motel.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record MotelCreatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long motelId, String motelName
) implements LoggableEvent {
    @Override public String action() { return "CREATE_MOTEL"; }
    @Override public String entityType() { return "Motel"; }
    @Override public String entityId() { return motelId.toString(); }
    @Override public String newValue() { return motelName; }
}

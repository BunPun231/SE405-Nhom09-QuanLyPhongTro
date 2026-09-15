package com.roomrental.modules.room.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record RoomUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long roomId, String oldNumber, String newNumber
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_ROOM"; }
    @Override public String entityType() { return "Room"; }
    @Override public String entityId() { return roomId.toString(); }
    @Override public String oldValue() { return oldNumber; }
    @Override public String newValue() { return newNumber; }
}

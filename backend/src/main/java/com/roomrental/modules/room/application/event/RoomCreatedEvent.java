package com.roomrental.modules.room.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record RoomCreatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long roomId, String roomNumber
) implements LoggableEvent {
    @Override public String action() { return "CREATE_ROOM"; }
    @Override public String entityType() { return "Room"; }
    @Override public String entityId() { return roomId.toString(); }
    @Override public String newValue() { return roomNumber; }
}

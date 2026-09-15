package com.roomrental.modules.room.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record RoomStatusUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long roomId, String oldStatus, String newStatus
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_ROOM_STATUS"; }
    @Override public String entityType() { return "Room"; }
    @Override public String entityId() { return roomId.toString(); }
    @Override public String oldValue() { return oldStatus; }
    @Override public String newValue() { return newStatus; }
}

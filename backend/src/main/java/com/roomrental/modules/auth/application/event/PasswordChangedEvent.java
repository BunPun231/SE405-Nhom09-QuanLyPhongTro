package com.roomrental.modules.auth.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record PasswordChangedEvent(
        UUID tenantId,
        UUID actorId,
        String actorRole
) implements LoggableEvent {
    @Override public String action() { return "CHANGE_PASSWORD"; }
    @Override public String entityType() { return "User"; }
    @Override public String entityId() { return actorId.toString(); }
    @Override public String newValue() { return "CHANGED"; }
}

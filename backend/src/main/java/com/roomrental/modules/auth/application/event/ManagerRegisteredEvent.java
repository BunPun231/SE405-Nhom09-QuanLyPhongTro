package com.roomrental.modules.auth.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ManagerRegisteredEvent(
        UUID tenantId,
        UUID actorId,
        String actorRole,
        String fullName
) implements LoggableEvent {
    @Override public String action() { return "REGISTER_MANAGER"; }
    @Override public String entityType() { return "User"; }
    @Override public String entityId() { return actorId.toString(); }
    @Override public String newValue() { return fullName; }
}

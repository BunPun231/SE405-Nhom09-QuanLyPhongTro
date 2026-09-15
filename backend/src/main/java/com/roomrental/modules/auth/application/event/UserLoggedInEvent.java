package com.roomrental.modules.auth.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record UserLoggedInEvent(
        UUID tenantId,
        UUID actorId,
        String actorRole
) implements LoggableEvent {
    @Override public String action() { return "USER_LOGIN"; }
    @Override public String entityType() { return "User"; }
    @Override public String entityId() { return actorId.toString(); }
    @Override public String newValue() { return "SUCCESS"; }
}

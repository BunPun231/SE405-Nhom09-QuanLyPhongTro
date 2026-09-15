package com.roomrental.modules.service.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ServiceCreatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long serviceId, String serviceName
) implements LoggableEvent {
    @Override public String action() { return "CREATE_SERVICE"; }
    @Override public String entityType() { return "RentalService"; }
    @Override public String entityId() { return serviceId.toString(); }
    @Override public String newValue() { return serviceName; }
}

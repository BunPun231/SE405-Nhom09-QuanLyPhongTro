package com.roomrental.common.event;

import java.util.UUID;

/**
 * Marker interface for all domain events that should be captured by the logging system.
 * Each module defines its own specific event records implementing this interface.
 * Default methods return null for optional fields.
 */
public interface LoggableEvent {

    UUID tenantId();

    UUID actorId();

    String actorRole();

    String action();

    String entityType();

    String entityId();

    default String oldValue() { return null; }

    default String newValue() { return null; }

    default String metadata() { return null; }
}

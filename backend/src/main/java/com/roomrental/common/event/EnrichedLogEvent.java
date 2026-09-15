package com.roomrental.common.event;

/**
 * Internal enriched wrapper around a LoggableEvent.
 * Created by DomainEventPublisher after capturing IP/User-Agent on the main thread.
 * Consumed by async listeners (ActivityLogListener, SecurityAuditLogListener).
 */
public record EnrichedLogEvent(
        LoggableEvent source,
        String ipAddress,
        String userAgent
) {}

package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record MeterReadingApprovedEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long meterReadingId, String status
) implements LoggableEvent {
    @Override public String action() { return "APPROVE_METER_READING"; }
    @Override public String entityType() { return "MeterReading"; }
    @Override public String entityId() { return meterReadingId.toString(); }
    @Override public String newValue() { return status; }
}

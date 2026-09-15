package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record MeterReadingSubmittedEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long meterReadingId, Long roomId, String newReading
) implements LoggableEvent {
    @Override public String action() { return "SUBMIT_METER_READING"; }
    @Override public String entityType() { return "MeterReading"; }
    @Override public String entityId() { return meterReadingId.toString(); }
    @Override public String newValue() { return newReading; }
    @Override public String metadata() { return "RoomID: " + roomId; }
}

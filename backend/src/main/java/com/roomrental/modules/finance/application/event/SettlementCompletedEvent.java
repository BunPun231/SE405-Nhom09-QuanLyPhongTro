package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record SettlementCompletedEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long contractId, String netAmount
) implements LoggableEvent {
    @Override public String action() { return "COMPLETE_SETTLEMENT"; }
    @Override public String entityType() { return "Contract"; }
    @Override public String entityId() { return contractId.toString(); }
    @Override public String newValue() { return netAmount; }
}

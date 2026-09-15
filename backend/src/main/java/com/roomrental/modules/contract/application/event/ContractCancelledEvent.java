package com.roomrental.modules.contract.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ContractCancelledEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long contractId, String oldStatus, String reason
) implements LoggableEvent {
    @Override public String action() { return "CANCEL_CONTRACT"; }
    @Override public String entityType() { return "Contract"; }
    @Override public String entityId() { return contractId.toString(); }
    @Override public String oldValue() { return oldStatus; }
    @Override public String newValue() { return "CANCELED"; }
    @Override public String metadata() { return reason; }
}

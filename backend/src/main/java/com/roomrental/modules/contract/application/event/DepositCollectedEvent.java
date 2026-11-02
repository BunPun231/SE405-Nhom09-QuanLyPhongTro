package com.roomrental.modules.contract.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record DepositCollectedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long contractId, String oldDepositStatus, String details
) implements LoggableEvent {
    public DepositCollectedEvent(UUID tenantId, UUID actorId, String actorRole,
                                 Long contractId, String oldDepositStatus) {
        this(tenantId, actorId, actorRole, contractId, oldDepositStatus, null);
    }

    @Override public String action() { return "COLLECT_DEPOSIT"; }
    @Override public String entityType() { return "Contract"; }
    @Override public String entityId() { return contractId.toString(); }
    @Override public String oldValue() { return oldDepositStatus; }
    @Override public String newValue() { return "PAID"; }
    @Override public String metadata() { return details; }
}

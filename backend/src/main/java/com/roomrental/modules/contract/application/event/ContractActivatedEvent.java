package com.roomrental.modules.contract.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ContractActivatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long contractId
) implements LoggableEvent {
    @Override public String action() { return "ACTIVATE_CONTRACT"; }
    @Override public String entityType() { return "Contract"; }
    @Override public String entityId() { return contractId.toString(); }
    @Override public String oldValue() { return "DRAFT"; }
    @Override public String newValue() { return "ACTIVE"; }
}

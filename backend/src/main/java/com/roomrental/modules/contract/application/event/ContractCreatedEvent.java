package com.roomrental.modules.contract.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record ContractCreatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long contractId, String status
) implements LoggableEvent {
    @Override public String action() { return "CREATE_CONTRACT"; }
    @Override public String entityType() { return "Contract"; }
    @Override public String entityId() { return contractId.toString(); }
    @Override public String newValue() { return status; }
}

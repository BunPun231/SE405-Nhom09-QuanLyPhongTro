package com.roomrental.modules.contract.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record DepositRefundedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long contractId, String oldDepositStatus
) implements LoggableEvent {
    @Override public String action() { return "REFUND_DEPOSIT"; }
    @Override public String entityType() { return "Contract"; }
    @Override public String entityId() { return contractId.toString(); }
    @Override public String oldValue() { return oldDepositStatus; }
    @Override public String newValue() { return "REFUNDED"; }
}

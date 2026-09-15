package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record InvoiceCancelledEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long invoiceId, String reason
) implements LoggableEvent {
    @Override public String action() { return "CANCEL_INVOICE"; }
    @Override public String entityType() { return "Invoice"; }
    @Override public String entityId() { return invoiceId.toString(); }
    @Override public String newValue() { return "VOID"; }
    @Override public String metadata() { return "Reason: " + reason; }
}

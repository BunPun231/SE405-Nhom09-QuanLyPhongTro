package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record InvoiceCreatedEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long invoiceId, String amount
) implements LoggableEvent {
    @Override public String action() { return "CREATE_INVOICE"; }
    @Override public String entityType() { return "Invoice"; }
    @Override public String entityId() { return invoiceId.toString(); }
    @Override public String newValue() { return amount; }
}

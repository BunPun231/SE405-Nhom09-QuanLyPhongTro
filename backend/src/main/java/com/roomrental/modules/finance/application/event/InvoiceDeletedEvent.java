package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record InvoiceDeletedEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long invoiceId
) implements LoggableEvent {
    @Override public String action() { return "DELETE_INVOICE"; }
    @Override public String entityType() { return "Invoice"; }
    @Override public String entityId() { return invoiceId.toString(); }
}

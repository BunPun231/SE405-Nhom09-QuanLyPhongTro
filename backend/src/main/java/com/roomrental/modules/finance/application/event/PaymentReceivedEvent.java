package com.roomrental.modules.finance.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

public record PaymentReceivedEvent(
    UUID tenantId, UUID actorId, String actorRole,
    Long transactionId, Long invoiceId, String amount
) implements LoggableEvent {
    @Override public String action() { return "RECEIVE_PAYMENT"; }
    @Override public String entityType() { return "Transaction"; }
    @Override public String entityId() { return transactionId.toString(); }
    @Override public String newValue() { return amount; }
    @Override public String metadata() { return "InvoiceID: " + invoiceId; }
}

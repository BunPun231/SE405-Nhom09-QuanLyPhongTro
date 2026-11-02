package com.roomrental.modules.resident.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.util.UUID;

/**
 * UC55 (BR55.7): system log when a resident's access is revoked automatically
 * because their contract was LIQUIDATED or CANCELED.
 */
public record ResidentAccessRevokedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        UUID residentId, Long contractId, String contractStatus
) implements LoggableEvent {
    @Override public String action() { return "AUTO_REVOKE_ACCESS"; }
    @Override public String entityType() { return "Resident"; }
    @Override public String entityId() { return residentId.toString(); }
    @Override public String oldValue() { return "ACTIVE"; }
    @Override public String newValue() { return "INACTIVE"; }
    @Override public String metadata() {
        return "{\"reason\":\"Contract_Ended\",\"contractId\":" + contractId
                + ",\"contractStatus\":\"" + contractStatus + "\"}";
    }
}

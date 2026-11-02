package com.roomrental.modules.resident.application.listener;

import com.roomrental.common.event.LoggableEvent;
import com.roomrental.modules.resident.application.service.ResidentAccessRevocationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.Set;

/**
 * UC55 trigger (BR55.1): listens to contract events and revokes resident access once
 * the contract becomes LIQUIDATED (settlement confirmed) or CANCELED.
 * Runs after the contract transaction commits so the contract status is final.
 * A periodic reconciliation covers contracts ended by any other path.
 */
@Slf4j
@Component
public class ResidentAccessRevocationListener {

    static final Set<String> TRIGGER_ACTIONS = Set.of("COMPLETE_SETTLEMENT", "CANCEL_CONTRACT", "LIQUIDATE_CONTRACT");
    static final Set<String> TRIGGER_VALUES = Set.of("LIQUIDATED", "CANCELED");

    private final ResidentAccessRevocationService revocationService;

    public ResidentAccessRevocationListener(ResidentAccessRevocationService revocationService) {
        this.revocationService = revocationService;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void onContractEvent(LoggableEvent event) {
        if (!isContractEndTrigger(event)) return;
        try {
            Long contractId = Long.valueOf(event.entityId());
            revocationService.revokeForContract(contractId, event.actorId(), event.actorRole());
        } catch (Exception e) {
            // The scheduled reconciliation below will retry.
            log.error("[UC55] Failed to revoke access for contract {}: {}", event.entityId(), e.getMessage(), e);
        }
    }

    static boolean isContractEndTrigger(LoggableEvent event) {
        if (event == null || !"Contract".equals(event.entityType()) || event.entityId() == null) {
            return false;
        }
        return TRIGGER_ACTIONS.contains(event.action()) || TRIGGER_VALUES.contains(event.newValue());
    }

    /** Safety net: every 10 minutes, revoke residents still linked to ended contracts. */
    @Scheduled(fixedDelay = 600_000, initialDelay = 60_000)
    public void reconcile() {
        try {
            int total = 0;
            for (Long contractId : revocationService.findEndedContractsWithActiveLinks()) {
                total += revocationService.revokeForContract(contractId, null, "SYSTEM");
            }
            if (total > 0) {
                log.info("[UC55] Reconciliation revoked access for {} residents", total);
            }
        } catch (Exception e) {
            log.error("[UC55] Reconciliation failed: {}", e.getMessage(), e);
        }
    }
}

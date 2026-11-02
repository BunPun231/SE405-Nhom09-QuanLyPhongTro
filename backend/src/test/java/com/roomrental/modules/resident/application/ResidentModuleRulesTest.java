package com.roomrental.modules.resident.application;

import com.roomrental.common.event.LoggableEvent;
import com.roomrental.modules.resident.application.dto.ResidentViews;
import com.roomrental.modules.resident.application.listener.ResidentAccessRevocationListenerTestAccess;
import com.roomrental.modules.resident.application.service.ResidentQueryServiceTestAccess;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class ResidentModuleRulesTest {

    private static ResidentViews.ContractItem contract(long id, String status) {
        return new ResidentViews.ContractItem(id, status, "101", "Khu A", null, null, null,
                null, null, null, true);
    }

    private static ResidentViews.Summary summary(BigDecimal debt, int count) {
        return new ResidentViews.Summary(UUID.randomUUID(), "A", "0901234567", null, "ACTIVE", null,
                1L, "LIQUIDATED", "101", "Khu A", "FORMER", debt, count);
    }

    @Test
    void deactivateBlockedWhileContractNotLiquidated() {
        String reason = ResidentQueryServiceTestAccess.blockReason("ACTIVE",
                List.of(contract(5, "ACTIVE")), summary(BigDecimal.ZERO, 0));
        assertNotNull(reason);
        assertTrue(reason.contains("#5"));
        assertNotNull(ResidentQueryServiceTestAccess.blockReason("ACTIVE",
                List.of(contract(6, "PENDING_LIQUIDATION")), summary(BigDecimal.ZERO, 0)));
    }

    @Test
    void deactivateBlockedWhenDebtRemains() {
        String reason = ResidentQueryServiceTestAccess.blockReason("ACTIVE",
                List.of(contract(5, "LIQUIDATED")), summary(new BigDecimal("150000"), 2));
        assertNotNull(reason);
        assertTrue(reason.contains("2 hóa đơn"));
    }

    @Test
    void deactivateAllowedAfterLiquidation() {
        assertNull(ResidentQueryServiceTestAccess.blockReason("ACTIVE",
                List.of(contract(5, "LIQUIDATED"), contract(3, "CANCELED")), summary(BigDecimal.ZERO, 0)));
        assertNotNull(ResidentQueryServiceTestAccess.blockReason("INACTIVE", List.of(), null));
    }

    @Test
    void filterAndStayHelpers() {
        assertEquals("ALL", ResidentQueryServiceTestAccess.normalize(null));
        assertEquals("LIVING", ResidentQueryServiceTestAccess.normalize(" living "));
        assertEquals("ALL", ResidentQueryServiceTestAccess.normalize("DROP TABLE"));
        assertEquals(31, ResidentQueryServiceTestAccess.stay(LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1)));
        assertEquals(0, ResidentQueryServiceTestAccess.stay(null, LocalDate.of(2026, 2, 1)));
    }

    @Test
    void revocationTriggersOnlyForEndedContracts() {
        assertTrue(ResidentAccessRevocationListenerTestAccess.isTrigger(event("Contract", "COMPLETE_SETTLEMENT", "CONFIRMED")));
        assertTrue(ResidentAccessRevocationListenerTestAccess.isTrigger(event("Contract", "CANCEL_CONTRACT", "CANCELED")));
        assertTrue(ResidentAccessRevocationListenerTestAccess.isTrigger(event("Contract", "ANY", "LIQUIDATED")));
        assertFalse(ResidentAccessRevocationListenerTestAccess.isTrigger(event("Contract", "CREATE_CONTRACT", "ACTIVE")));
        assertFalse(ResidentAccessRevocationListenerTestAccess.isTrigger(event("Invoice", "CANCEL_CONTRACT", "CANCELED")));
    }

    private static LoggableEvent event(String entityType, String action, String newValue) {
        return new LoggableEvent() {
            @Override public UUID tenantId() { return UUID.randomUUID(); }
            @Override public UUID actorId() { return UUID.randomUUID(); }
            @Override public String actorRole() { return "MANAGER"; }
            @Override public String action() { return action; }
            @Override public String entityType() { return entityType; }
            @Override public String entityId() { return "12"; }
            @Override public String newValue() { return newValue; }
        };
    }
}

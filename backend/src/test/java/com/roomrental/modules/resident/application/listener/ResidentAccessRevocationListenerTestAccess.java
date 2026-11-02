package com.roomrental.modules.resident.application.listener;

import com.roomrental.common.event.LoggableEvent;

/** Exposes the UC55 trigger rule to tests. */
public final class ResidentAccessRevocationListenerTestAccess {
    private ResidentAccessRevocationListenerTestAccess() {}

    public static boolean isTrigger(LoggableEvent event) {
        return ResidentAccessRevocationListener.isContractEndTrigger(event);
    }
}

package com.roomrental.modules.finance.interfaces.rest.dto;

/**
 * UC80 buoc 5b/5c: dong hop dong sau khi thu them, hoac dong & ghi nhan no xau.
 */
public record SettlementFinalizeRequest(
    boolean closeAsBadDebt,
    String note
) {}

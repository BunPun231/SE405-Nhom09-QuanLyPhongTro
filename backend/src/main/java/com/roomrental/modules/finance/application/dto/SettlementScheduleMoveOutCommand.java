package com.roomrental.modules.finance.application.dto;

import java.time.LocalDate;

public record SettlementScheduleMoveOutCommand(
    Long contractId,
    LocalDate moveOutDate,
    String moveOutReason
) {}

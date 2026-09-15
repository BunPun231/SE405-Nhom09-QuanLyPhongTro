package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record SettlementScheduleMoveOutRequest(
    @NotNull Long contractId,
    @NotNull LocalDate moveOutDate,
    String moveOutReason
) {}

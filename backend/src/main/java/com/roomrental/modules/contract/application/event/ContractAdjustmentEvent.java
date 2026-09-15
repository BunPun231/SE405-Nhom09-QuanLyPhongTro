package com.roomrental.modules.contract.application.event;

import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import java.time.LocalDateTime;
import java.util.UUID;

public record ContractAdjustmentEvent(
        Long contractId,
        UUID tenantId,
        UUID actorId,
        ContractAdjustmentType type,
        LocalDateTime occurredAt
) {
}

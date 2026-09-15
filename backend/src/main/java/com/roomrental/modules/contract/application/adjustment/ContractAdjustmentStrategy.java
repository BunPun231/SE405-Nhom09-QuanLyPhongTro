package com.roomrental.modules.contract.application.adjustment;

import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import com.roomrental.modules.contract.domain.model.Contract;

public interface ContractAdjustmentStrategy {
    ContractAdjustmentType getType();

    /**
     * Process the adjustment on the given contract.
     * @return the created ContractAppendix ID, or null if no appendix was created
     */
    Long process(Contract contract, ContractAdjustmentRequest request);
}

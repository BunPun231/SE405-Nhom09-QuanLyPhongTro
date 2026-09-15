package com.roomrental.modules.contract.application.adjustment;

import com.roomrental.common.exception.BaseException;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import com.roomrental.modules.contract.domain.model.Contract;
import java.time.LocalDate;
import org.springframework.stereotype.Component;

@Component
public class MoveOutNoticeStrategy implements ContractAdjustmentStrategy {

    @Override
    public ContractAdjustmentType getType() {
        return ContractAdjustmentType.MOVE_OUT_NOTICE;
    }

    @Override
    public Long process(Contract contract, ContractAdjustmentRequest request) {
        LocalDate intendedMoveOutDate = request.intendedMoveOutDate();
        if (intendedMoveOutDate == null) {
            throw BaseException.badRequest("intendedMoveOutDate: required");
        }
        if (intendedMoveOutDate.isBefore(LocalDate.now())) {
            throw BaseException.badRequest("intendedMoveOutDate: must be today or later");
        }
        contract.setIntendedMoveOutDate(intendedMoveOutDate);
        return null; // No appendix created for MOVE_OUT_NOTICE
    }
}

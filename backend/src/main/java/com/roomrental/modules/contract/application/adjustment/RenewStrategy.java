package com.roomrental.modules.contract.application.adjustment;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.model.ContractAppendix;
import com.roomrental.modules.contract.domain.repository.ContractAppendixRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class RenewStrategy implements ContractAdjustmentStrategy {
    private final ContractAppendixRepository appendixRepository;

    public RenewStrategy(ContractAppendixRepository appendixRepository) {
        this.appendixRepository = appendixRepository;
    }

    @Override
    public ContractAdjustmentType getType() {
        return ContractAdjustmentType.RENEW;
    }

    @Override
    public Long process(Contract contract, ContractAdjustmentRequest request) {
        LocalDate newEndDate = request.newEndDate();
        if (newEndDate == null) {
            throw BaseException.badRequest("newEndDate: required");
        }
        if (!newEndDate.isAfter(contract.getEndDate())) {
            throw BaseException.badRequest("newEndDate: must be after current endDate");
        }

        LocalDate effectiveDate = request.effectiveDate() != null ? request.effectiveDate() : contract.getEndDate();
        UUID actorId = SecurityUtils.getCurrentUserId();

        ContractAppendix appendix = new ContractAppendix();
        appendix.setTenantId(contract.getTenantId());
        appendix.setContractId(contract.getId());
        appendix.setEffectiveDate(effectiveDate);
        appendix.setAppendixType(getType().name());
        appendix.setMetadata("{\"newEndDate\":\"" + newEndDate + "\"}");
        appendix.setCreatedBy(actorId);
        appendix.setCreatedAt(LocalDateTime.now());
        ContractAppendix saved = appendixRepository.save(appendix);

        contract.setEndDate(newEndDate);
        return saved.getId();
    }
}

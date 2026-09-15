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
public class ManualAppendixStrategy implements ContractAdjustmentStrategy {
    private final ContractAppendixRepository appendixRepository;

    public ManualAppendixStrategy(ContractAppendixRepository appendixRepository) {
        this.appendixRepository = appendixRepository;
    }

    @Override
    public ContractAdjustmentType getType() {
        return ContractAdjustmentType.MANUAL_CLAUSE;
    }

    @Override
    public Long process(Contract contract, ContractAdjustmentRequest request) {
        LocalDate effectiveDate = request.effectiveDate();
        if (effectiveDate == null) {
            throw BaseException.badRequest("effectiveDate: required");
        }
        if (request.metadata() == null || request.metadata().isBlank()) {
            throw BaseException.badRequest("metadata: required");
        }

        UUID actorId = SecurityUtils.getCurrentUserId();
        ContractAppendix appendix = new ContractAppendix();
        appendix.setTenantId(contract.getTenantId());
        appendix.setContractId(contract.getId());
        appendix.setEffectiveDate(effectiveDate);
        appendix.setAppendixType(getType().name());
        appendix.setMetadata(request.metadata());
        appendix.setCreatedBy(actorId);
        appendix.setCreatedAt(LocalDateTime.now());
        ContractAppendix saved = appendixRepository.save(appendix);
        return saved.getId();
    }
}

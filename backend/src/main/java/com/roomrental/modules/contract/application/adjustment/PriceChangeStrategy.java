package com.roomrental.modules.contract.application.adjustment;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.model.ContractAppendix;
import com.roomrental.modules.contract.domain.repository.ContractAppendixRepository;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.invoice.domain.repository.InvoiceReadRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class PriceChangeStrategy implements ContractAdjustmentStrategy {
    private final ContractAppendixRepository appendixRepository;
    private final InvoiceReadRepository invoiceReadRepository;
    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;

    public PriceChangeStrategy(
            ContractAppendixRepository appendixRepository,
            InvoiceReadRepository invoiceReadRepository,
            ContractRepository contractRepository,
            RoomRepository roomRepository
    ) {
        this.appendixRepository = appendixRepository;
        this.invoiceReadRepository = invoiceReadRepository;
        this.contractRepository = contractRepository;
        this.roomRepository = roomRepository;
    }

    @Override
    public ContractAdjustmentType getType() {
        return ContractAdjustmentType.PRICE_CHANGE;
    }

    @Override
    public Long process(Contract contract, ContractAdjustmentRequest request) {
        LocalDate effectiveDate = request.effectiveDate();
        if (effectiveDate == null) {
            throw BaseException.badRequest("effectiveDate: required");
        }
        BigDecimal newRentPrice = request.newRentPrice();
        if (newRentPrice == null || newRentPrice.compareTo(BigDecimal.ZERO) <= 0) {
            throw BaseException.badRequest("newRentPrice: must be positive");
        }

        if (invoiceReadRepository.existsPaidInvoiceCovering(contract.getId(), effectiveDate)) {
            throw BaseException.badRequest("effectiveDate: overlaps a paid invoice period");
        }

        UUID actorId = SecurityUtils.getCurrentUserId();
        ContractAppendix appendix = new ContractAppendix();
        appendix.setTenantId(contract.getTenantId());
        appendix.setContractId(contract.getId());
        appendix.setEffectiveDate(effectiveDate);
        appendix.setNewRentPrice(newRentPrice);
        appendix.setAppendixType(getType().name());
        appendix.setMetadata(null);
        if (request.applyToCurrentContracts() && request.newServicePrices() != null && !request.newServicePrices().isBlank()) {
            appendix.setNewServicePrices(request.newServicePrices());
        }
        appendix.setCreatedBy(actorId);
        appendix.setCreatedAt(LocalDateTime.now());
        ContractAppendix saved = appendixRepository.save(appendix);

        if (request.applyToCurrentContracts()) {
            Room currentRoom = roomRepository.findById(contract.getRoomId())
                .orElseThrow(() -> BaseException.notFound("Room", contract.getRoomId()));
            Long motelId = currentRoom.getMotelId();
            List<Contract> activeContracts = contractRepository.findActiveByTenantId(contract.getTenantId());
            for (Contract active : activeContracts) {
                if (active.getId().equals(contract.getId())) {
                    continue;
                }
                Room room = roomRepository.findById(active.getRoomId()).orElse(null);
                if (room == null || !motelId.equals(room.getMotelId())) {
                    continue;
                }
                if (invoiceReadRepository.existsPaidInvoiceCovering(active.getId(), effectiveDate)) {
                    throw BaseException.badRequest("effectiveDate: overlaps a paid invoice period for contract " + active.getId());
                }

                ContractAppendix bulkAppendix = new ContractAppendix();
                bulkAppendix.setTenantId(active.getTenantId());
                bulkAppendix.setContractId(active.getId());
                bulkAppendix.setEffectiveDate(effectiveDate);
                bulkAppendix.setNewRentPrice(newRentPrice);
                bulkAppendix.setAppendixType(getType().name());
                bulkAppendix.setMetadata(null);
                if (request.newServicePrices() != null && !request.newServicePrices().isBlank()) {
                    bulkAppendix.setNewServicePrices(request.newServicePrices());
                }
                bulkAppendix.setCreatedBy(actorId);
                bulkAppendix.setCreatedAt(LocalDateTime.now());
                appendixRepository.save(bulkAppendix);
            }
        }

        return saved.getId();
    }
}

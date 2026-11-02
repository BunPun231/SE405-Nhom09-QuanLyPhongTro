package com.roomrental.modules.finance.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.finance.application.dto.*;
import com.roomrental.modules.finance.application.event.SettlementCompletedEvent;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.model.Transaction;
import com.roomrental.modules.finance.domain.model.ResidentBalance;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import com.roomrental.modules.finance.domain.repository.InvoiceDetailRepository;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.repository.ResidentBalanceRepository;
import com.roomrental.modules.finance.domain.repository.TransactionRepository;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.model.ServicePricing;
import com.roomrental.modules.service.domain.model.ServiceTierPricing;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import com.roomrental.modules.finance.application.strategy.BillingStrategy;
import com.roomrental.modules.finance.application.strategy.BillingContext;
import com.roomrental.modules.finance.application.strategy.BillingStrategyFactory;
import com.roomrental.modules.room.domain.model.Room;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.Comparator;

@Service
public class SettlementService {

    private final ContractRepository contractRepository;
    private final InvoiceRepository invoiceRepository;
    private final InvoiceDetailRepository invoiceDetailRepository;
    private final com.roomrental.modules.room.domain.repository.RoomRepository roomRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final ServiceUsageRepository serviceUsageRepository;
    private final RentalServiceRepository rentalServiceRepository;
    private final ServicePricingRepository servicePricingRepository;
    private final ResidentBalanceRepository residentBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final BillingStrategyFactory strategyFactory;
    private final ApplicationEventPublisher eventPublisher;
    private final CloudinaryService cloudinaryService;

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(SettlementService.class);

    public SettlementService(
            ContractRepository contractRepository,
            InvoiceRepository invoiceRepository,
            InvoiceDetailRepository invoiceDetailRepository,
            com.roomrental.modules.room.domain.repository.RoomRepository roomRepository,
            MeterReadingRepository meterReadingRepository,
            ServiceUsageRepository serviceUsageRepository,
            RentalServiceRepository rentalServiceRepository,
            ServicePricingRepository servicePricingRepository,
            ResidentBalanceRepository residentBalanceRepository,
            TransactionRepository transactionRepository,
            BillingStrategyFactory strategyFactory,
            ApplicationEventPublisher eventPublisher,
            CloudinaryService cloudinaryService) {
        this.cloudinaryService = cloudinaryService;
        this.contractRepository = contractRepository;
        this.invoiceRepository = invoiceRepository;
        this.invoiceDetailRepository = invoiceDetailRepository;
        this.roomRepository = roomRepository;
        this.meterReadingRepository = meterReadingRepository;
        this.serviceUsageRepository = serviceUsageRepository;
        this.rentalServiceRepository = rentalServiceRepository;
        this.servicePricingRepository = servicePricingRepository;
        this.residentBalanceRepository = residentBalanceRepository;
        this.transactionRepository = transactionRepository;
        this.strategyFactory = strategyFactory;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public SettlementResult calculate(SettlementCommand command) {
      UUID tenantId = SecurityUtils.requireTenantId();
      Contract contract = contractRepository.findByIdAndTenantId(command.contractId(), tenantId)
          .orElseThrow(() -> BaseException.notFound("Contract", command.contractId()));

      if (contract.getStatus() == Contract.ContractStatus.DRAFT) {
          throw BaseException.badRequest("Cannot compute settlement for DRAFT contract");
      }
      if (contract.getDepositStatus() == Contract.DepositStatus.UNPAID) {
          throw BaseException.badRequest("Cannot compute settlement for UNPAID deposit contract");
      }
      requireSettleableStatus(contract);

      SettlementComputation comp = computeSettlement(contract, command.moveOutDate(), command.finalElectricReading(), command.finalWaterReading(), command.damages());

        return new SettlementResult(
            contract.getId(),
            comp.deposit(),
            comp.currentDebt(),
            comp.proRatedRent(),
            comp.finalUtilities(),
            comp.repairFees(),
            comp.netAmount(),
            null
        );
    }

    @Transactional
    public SettlementConfirmationResult confirmSettlement(SettlementConfirmCommand command) {
      UUID tenantId = SecurityUtils.requireTenantId();
      Contract contract = contractRepository.findByIdAndTenantId(command.contractId(), tenantId)
          .orElseThrow(() -> BaseException.notFound("Contract", command.contractId()));

      if (contract.getStatus() == Contract.ContractStatus.DRAFT) {
          throw BaseException.badRequest("Cannot confirm settlement for DRAFT contract");
      }
      if (contract.getDepositStatus() == Contract.DepositStatus.UNPAID) {
          throw BaseException.badRequest("Cannot confirm settlement for UNPAID deposit contract");
      }
      requireSettleableStatus(contract);
      if (findSettlementInvoice(contract.getId()) != null) {
          throw BaseException.conflict("Hop dong da duoc tat toan, dang cho thu them hoac dong hop dong");
      }

      SettlementComputation comp = computeSettlement(contract, command.moveOutDate(), command.finalElectricReading(), command.finalWaterReading(), command.damages());
      List<DamageItemInput> evidencedDamages = uploadEvidence(contract.getId(), command.damages());

        BigDecimal remainingDeposit = comp.deposit();
        BigDecimal oldDebtDeducted = BigDecimal.ZERO;

        for (Invoice pending : comp.unpaidInvoices()) {
            if (remainingDeposit.compareTo(BigDecimal.ZERO) <= 0) break;
            BigDecimal remainingInvAmount = pending.getTotalAmount()
                .subtract(pending.getPaidAmount() != null ? pending.getPaidAmount() : BigDecimal.ZERO)
                .subtract(pending.getBalanceDeduction() != null ? pending.getBalanceDeduction() : BigDecimal.ZERO);
            BigDecimal toDeduct = remainingInvAmount.min(remainingDeposit);
            
            pending.setBalanceDeduction((pending.getBalanceDeduction() != null ? pending.getBalanceDeduction() : BigDecimal.ZERO).add(toDeduct));
            remainingDeposit = remainingDeposit.subtract(toDeduct);
            oldDebtDeducted = oldDebtDeducted.add(toDeduct);
            
            BigDecimal newRemaining = pending.getTotalAmount()
                .subtract(pending.getPaidAmount() != null ? pending.getPaidAmount() : BigDecimal.ZERO)
                .subtract(pending.getBalanceDeduction());
            if (newRemaining.compareTo(BigDecimal.ZERO) <= 0) {
                pending.setStatus(Invoice.InvoiceStatus.PAID);
            }
            invoiceRepository.save(pending);
        }

        Invoice invoice = new Invoice();
        invoice.setTenantId(tenantId);
        invoice.setContractId(contract.getId());
        invoice.setRoomId(contract.getRoomId());
        invoice.setBillingMonth(comp.moveOutDate().withDayOfMonth(1));
        invoice.setInvoiceType(Invoice.InvoiceType.SETTLEMENT);
        invoice.setTotalAmount(comp.settlementTotal());
        invoice.setDueDate(java.time.LocalDate.now());
        invoice.setCreatedAt(OffsetDateTime.now());
        invoice.setUpdatedAt(OffsetDateTime.now());
        invoice.setCalculationSnapshot(buildSnapshot(comp, evidencedDamages));

        BigDecimal settlementDeduct = comp.settlementTotal().min(remainingDeposit);
        invoice.setBalanceDeduction(settlementDeduct);
        invoice.setPaidAmount(BigDecimal.ZERO);
        remainingDeposit = remainingDeposit.subtract(settlementDeduct);

        BigDecimal settlementRemaining = invoice.getTotalAmount().subtract(invoice.getBalanceDeduction());
        if (settlementRemaining.compareTo(BigDecimal.ZERO) <= 0) {
            invoice.setStatus(Invoice.InvoiceStatus.PAID);
        } else {
            invoice.setStatus(Invoice.InvoiceStatus.PENDING);
        }
        
        Invoice savedInvoice = invoiceRepository.save(invoice);

        List<InvoiceDetail> allDetails = new ArrayList<>();
        allDetails.addAll(comp.damageDetails());
        allDetails.addAll(comp.utilityDetails());
        
        InvoiceDetail rentDetail = new InvoiceDetail();
        rentDetail.setDescription("Tiền phòng theo ngày");
        rentDetail.setQuantity(BigDecimal.ONE);
        rentDetail.setUnitPrice(comp.proRatedRent());
        rentDetail.setLineTotal(comp.proRatedRent());
        allDetails.add(rentDetail);

        for (InvoiceDetail d : allDetails) {
            d.setInvoiceId(savedInvoice.getId());
        }
        invoiceDetailRepository.saveAll(allDetails);

        if (!comp.generatedReadings().isEmpty()) {
            meterReadingRepository.saveAll(comp.generatedReadings());
        }

        List<ServiceUsage> cancelledUsages = serviceUsageRepository.findBillableByRoomId(contract.getRoomId()).stream()
                .peek(usage -> usage.setStatus(ServiceUsage.ServiceUsageStatus.CANCELLED))
                .peek(usage -> usage.setUpdatedAt(OffsetDateTime.now()))
                .toList();
        if (!cancelledUsages.isEmpty()) {
            serviceUsageRepository.saveAll(cancelledUsages);
        }

        Transaction refundTransaction = null;
        BigDecimal refundAmount = remainingDeposit.max(BigDecimal.ZERO);
        if (refundAmount.compareTo(BigDecimal.ZERO) > 0) {
            refundTransaction = new Transaction();
            refundTransaction.setTenantId(tenantId);
            refundTransaction.setInvoiceId(savedInvoice.getId());
            refundTransaction.setAmount(refundAmount);
            refundTransaction.setTransactionRef("REFUND-" + contract.getId() + "-" + UUID.randomUUID().toString().substring(0, 8));
            refundTransaction.setPaymentMethod(Transaction.PaymentMethod.CASH);
            refundTransaction.setStatus(Transaction.TransactionStatus.SUCCESS);
            refundTransaction.setPaidAt(OffsetDateTime.now());
            refundTransaction.setCreatedAt(OffsetDateTime.now());
            refundTransaction.setOverpaidAmount(BigDecimal.ZERO);
            refundTransaction.setCreditBalanceSnapshot(getCurrentResidentBalance(contract.getId()));
            refundTransaction = transactionRepository.save(refundTransaction);
        }

        // UC69: Coc duoc hoan lai toan bo -> REFUNDED, bi khau tru (mot phan/toan bo) -> DEDUCTED.
        if (comp.deposit().compareTo(BigDecimal.ZERO) > 0) {
            contract.setDepositStatus(refundAmount.compareTo(comp.deposit()) >= 0
                ? Contract.DepositStatus.REFUNDED
                : Contract.DepositStatus.DEDUCTED);
        }

        if (savedInvoice.getStatus() == Invoice.InvoiceStatus.PAID) {
            liquidateContract(contract, comp.repairFees().compareTo(BigDecimal.ZERO) > 0, "CONFIRMED");
        } else {
            contract.setStatus(Contract.ContractStatus.PENDING_LIQUIDATION);
        }
        
        contract.setUpdatedAt(java.time.LocalDateTime.now());
        Contract savedContract = contractRepository.save(contract);
        Room savedRoom = roomRepository.findById(savedContract.getRoomId()).orElse(null);
        savedInvoice.setDetails(allDetails);

        return new SettlementConfirmationResult(
            savedContract.getId(),
            savedContract.getStatus() != null ? savedContract.getStatus().name() : null,
            savedContract.getRoomId(),
            savedRoom != null && savedRoom.getStatus() != null ? savedRoom.getStatus().name() : null,
            comp.deposit(),
            oldDebtDeducted,
            settlementDeduct,
            comp.netAmount(),
            toInvoiceResult(savedInvoice),
            toInvoiceDetailResults(invoiceDetailRepository.findByInvoiceId(savedInvoice.getId())),
            refundTransaction != null ? toTransactionResult(refundTransaction) : null
        );
    }

    @Transactional
    public void scheduleMoveOut(SettlementScheduleMoveOutCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(command.contractId(), tenantId)
            .orElseThrow(() -> BaseException.notFound("Contract", command.contractId()));

        if (!contract.isActive()) {
            throw BaseException.badRequest("Only active contracts can schedule move out");
        }

        contract.setIntendedMoveOutDate(command.moveOutDate());
        contract.setMoveOutReason(command.moveOutReason());
        contract.markForLiquidation();
        contract.setUpdatedAt(java.time.LocalDateTime.now());

        contractRepository.save(contract);
    }

    /**
     * Trang thai tat toan cua hop dong (de app hien buoc "cho thu them").
     */
    @Transactional(readOnly = true)
    public SettlementStatusResult getStatus(Long contractId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(contractId, tenantId)
            .orElseThrow(() -> BaseException.notFound("Contract", contractId));
        return toStatusResult(contract, findSettlementInvoice(contractId));
    }

    /**
     * UC80 buoc 5b/5c: Dong hop dong sau khi khach da thanh toan hoa don tat toan,
     * hoac dong & ghi nhan no xau khi khach khong thanh toan.
     */
    @Transactional
    public SettlementStatusResult finalizeSettlement(Long contractId, boolean closeAsBadDebt, String note) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(contractId, tenantId)
            .orElseThrow(() -> BaseException.notFound("Contract", contractId));
        if (contract.getStatus() != Contract.ContractStatus.PENDING_LIQUIDATION) {
            throw BaseException.badRequest("Hop dong khong o trang thai cho tat toan");
        }
        Invoice settlement = findSettlementInvoice(contractId);
        if (settlement == null) {
            throw BaseException.badRequest("Hop dong chua co bang tat toan, vui long thuc hien tat toan truoc");
        }
        boolean paid = settlement.getStatus() == Invoice.InvoiceStatus.PAID;
        if (!paid && !closeAsBadDebt) {
            throw BaseException.badRequest("Hoa don tat toan chua duoc thanh toan");
        }
        if (!paid && (note == null || note.isBlank())) {
            throw BaseException.badRequest("Vui long nhap ghi chu khi dong hop dong va ghi nhan no xau");
        }
        boolean hasDamage = snapshotRepairFees(settlement.getCalculationSnapshot()).compareTo(BigDecimal.ZERO) > 0;
        liquidateContract(contract, hasDamage, paid ? "CONFIRMED" : "BAD_DEBT: " + note.trim());
        contract.setUpdatedAt(java.time.LocalDateTime.now());
        Contract saved = contractRepository.save(contract);
        return toStatusResult(saved, settlement);
    }

    private void requireSettleableStatus(Contract contract) {
        if (contract.getStatus() == Contract.ContractStatus.CANCELED
                || contract.getStatus() == Contract.ContractStatus.LIQUIDATED) {
            throw BaseException.badRequest("Hop dong da ket thuc, khong the tat toan");
        }
    }

    private void liquidateContract(Contract contract, boolean hasDamage, String outcome) {
        contract.liquidate();
        roomRepository.findById(contract.getRoomId()).ifPresent(room -> {
            // BR80.6 / BR02: phong co hu hong chuyen sang REPAIRING thay vi EMPTY.
            room.setStatus(hasDamage
                ? com.roomrental.modules.room.domain.model.RoomStatus.REPAIRING
                : com.roomrental.modules.room.domain.model.RoomStatus.EMPTY);
            room.setCurrentResidentsCount(0);
            roomRepository.save(room);
        });
        eventPublisher.publishEvent(new SettlementCompletedEvent(
            contract.getTenantId(), SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
            contract.getId(), outcome
        ));
    }

    private Invoice findSettlementInvoice(Long contractId) {
        org.springframework.data.domain.Page<Invoice> page =
            invoiceRepository.findByContractId(contractId, org.springframework.data.domain.Pageable.unpaged());
        if (page == null) {
            return null;
        }
        return page.getContent().stream()
            .filter(inv -> inv.getInvoiceType() == Invoice.InvoiceType.SETTLEMENT)
            .filter(inv -> inv.getStatus() != Invoice.InvoiceStatus.VOID)
            .findFirst()
            .orElse(null);
    }

    private SettlementStatusResult toStatusResult(Contract contract, Invoice settlement) {
        Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        return new SettlementStatusResult(
            contract.getId(),
            contract.getStatus() != null ? contract.getStatus().name() : null,
            contract.getDepositStatus() != null ? contract.getDepositStatus().name() : null,
            room != null && room.getStatus() != null ? room.getStatus().name() : null,
            settlement != null ? settlement.getId() : null,
            settlement != null && settlement.getStatus() != null ? settlement.getStatus().name() : null,
            settlement != null ? settlement.getTotalAmount() : null,
            settlement != null ? settlement.getBalanceDeduction() : null,
            settlement != null ? settlement.getPaidAmount() : null,
            settlement != null ? settlement.getRemainingAmount() : null,
            settlement != null ? snapshotRepairFees(settlement.getCalculationSnapshot()) : null
        );
    }

    /**
     * BR80.3 (BR01): Moi hang muc khau tru > 0 bat buoc co ten va anh bang chung.
     */
    static void validateDamages(List<DamageItemInput> damages) {
        if (damages == null) {
            return;
        }
        for (DamageItemInput item : damages) {
            if (item == null || item.penaltyFee() == null) {
                continue;
            }
            if (item.penaltyFee().compareTo(BigDecimal.ZERO) < 0) {
                throw BaseException.badRequest("Phi hu hong khong duoc am");
            }
            if (item.penaltyFee().compareTo(BigDecimal.ZERO) > 0) {
                if (item.itemName() == null || item.itemName().isBlank()) {
                    throw BaseException.badRequest("Vui long nhap ten hang muc hu hong");
                }
                if (item.imageUrl() == null || item.imageUrl().isBlank()) {
                    throw BaseException.badRequest(
                        "Hang muc '" + item.itemName() + "' can it nhat 01 anh bang chung de khau tru tien coc");
                }
            }
        }
    }

    /**
     * Anh bang chung gui len dang base64 duoc tai len Cloudinary; neu khong tai duoc (vd. moi
     * truong dev khong cau hinh Cloudinary) van ghi nhan la co bang chung de khong chan nghiep vu.
     */
    private List<DamageItemInput> uploadEvidence(Long contractId, List<DamageItemInput> damages) {
        List<DamageItemInput> result = new ArrayList<>();
        if (damages == null) {
            return result;
        }
        for (DamageItemInput item : damages) {
            if (item == null || item.penaltyFee() == null || item.penaltyFee().compareTo(BigDecimal.ZERO) <= 0) {
                continue;
            }
            String ref = item.imageUrl();
            if (ref != null && !ref.startsWith("http://") && !ref.startsWith("https://")) {
                String raw = ref.contains(",") && ref.startsWith("data:") ? ref.substring(ref.indexOf(',') + 1) : ref;
                String uploaded = null;
                try {
                    byte[] bytes = java.util.Base64.getDecoder().decode(raw.trim());
                    if (cloudinaryService != null) {
                        uploaded = cloudinaryService.uploadImage(bytes, "settlements/" + contractId);
                    }
                } catch (IllegalArgumentException ex) {
                    throw BaseException.badRequest("Anh bang chung cua '" + item.itemName() + "' khong hop le");
                } catch (Exception ex) {
                    log.warn("Upload settlement evidence failed for contract {}: {}", contractId, ex.getMessage());
                }
                ref = uploaded != null ? uploaded : "inline-evidence:" + raw.length() + "b64";
            }
            result.add(new DamageItemInput(item.itemName(), item.penaltyFee(), ref));
        }
        return result;
    }

    private String buildSnapshot(SettlementComputation comp, List<DamageItemInput> damages) {
        java.util.Map<String, Object> snapshot = new java.util.LinkedHashMap<>();
        snapshot.put("type", "SETTLEMENT");
        snapshot.put("moveOutDate", comp.moveOutDate().toString());
        snapshot.put("deposit", comp.deposit());
        snapshot.put("currentDebt", comp.currentDebt());
        snapshot.put("proRatedRent", comp.proRatedRent());
        snapshot.put("finalUtilities", comp.finalUtilities());
        snapshot.put("repairFees", comp.repairFees());
        snapshot.put("netAmount", comp.netAmount());
        List<java.util.Map<String, Object>> items = new ArrayList<>();
        for (DamageItemInput d : damages) {
            java.util.Map<String, Object> m = new java.util.LinkedHashMap<>();
            m.put("itemName", d.itemName());
            m.put("penaltyFee", d.penaltyFee());
            m.put("evidence", d.imageUrl());
            items.add(m);
        }
        snapshot.put("damages", items);
        try {
            return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(snapshot);
        } catch (com.fasterxml.jackson.core.JsonProcessingException ex) {
            return null;
        }
    }

    static BigDecimal snapshotRepairFees(String snapshot) {
        if (snapshot == null || snapshot.isBlank()) {
            return BigDecimal.ZERO;
        }
        try {
            com.fasterxml.jackson.databind.JsonNode node =
                new com.fasterxml.jackson.databind.ObjectMapper().readTree(snapshot);
            if (node.isTextual()) {
                node = new com.fasterxml.jackson.databind.ObjectMapper().readTree(node.asText());
            }
            com.fasterxml.jackson.databind.JsonNode fees = node.get("repairFees");
            return fees != null && fees.isNumber() ? fees.decimalValue() : BigDecimal.ZERO;
        } catch (Exception ex) {
            return BigDecimal.ZERO;
        }
    }

    private record SettlementComputation(
        java.time.LocalDate moveOutDate,
        BigDecimal proRatedRent,
        BigDecimal repairFees,
        BigDecimal finalUtilities,
        BigDecimal settlementTotal,
        BigDecimal currentDebt,
        BigDecimal deposit,
        BigDecimal netAmount,
        List<Invoice> unpaidInvoices,
        List<InvoiceDetail> damageDetails,
        List<InvoiceDetail> utilityDetails,
        List<MeterReading> generatedReadings
    ) {}

    private SettlementComputation computeSettlement(
            Contract contract, 
            java.time.LocalDate requestedMoveOutDate,
            BigDecimal finalElectricReading,
            BigDecimal finalWaterReading,
            List<DamageItemInput> damages) {
        java.time.LocalDate moveOutDate = requestedMoveOutDate != null ? requestedMoveOutDate : contract.getIntendedMoveOutDate();
        if (moveOutDate == null) {
            throw BaseException.badRequest("Move out date must be provided or scheduled");
        }
        validateDamages(damages);

        long daysLived = moveOutDate.getDayOfMonth();
        int daysInMonth = YearMonth.from(moveOutDate).lengthOfMonth();
        BigDecimal proRatedRent = contract.getRentPrice()
            .multiply(BigDecimal.valueOf(daysLived))
            .divide(BigDecimal.valueOf(daysInMonth), 2, java.math.RoundingMode.HALF_UP);

        BigDecimal repairFees = BigDecimal.ZERO;
        List<InvoiceDetail> damageDetails = new ArrayList<>();
        if (damages != null) {
            for (DamageItemInput item : damages) {
                if (item.penaltyFee() != null && item.penaltyFee().compareTo(BigDecimal.ZERO) > 0) {
                    repairFees = repairFees.add(item.penaltyFee());
                    InvoiceDetail d = new InvoiceDetail();
                    d.setDescription(item.itemName() != null ? item.itemName() : "Bồi thường");
                    d.setQuantity(BigDecimal.ONE);
                    d.setUnitPrice(item.penaltyFee());
                    d.setLineTotal(item.penaltyFee());
                    damageDetails.add(d);
                }
            }
        }

        BigDecimal finalUtilities = BigDecimal.ZERO;
        List<InvoiceDetail> utilityDetails = new ArrayList<>();
        List<MeterReading> generatedReadings = new ArrayList<>();
        
        List<ServiceUsage> usages = serviceUsageRepository.findBillableByRoomId(contract.getRoomId());
        Long motelId = roomRepository.findById(contract.getRoomId()).get().getMotelId();
        
        for (ServiceUsage usage : usages) {
            RentalService service = rentalServiceRepository.findByIdAndMotelId(usage.getServiceId(), motelId).orElse(null);
            if (service == null) continue;

            if (service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.PER_INDEX
                    || service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.METERED) {
                BigDecimal finalReading = null;
                if (service.getName().toLowerCase().contains("điện")) {
                    finalReading = finalElectricReading;
                } else if (service.getName().toLowerCase().contains("nước")) {
                    finalReading = finalWaterReading;
                }

                if (finalReading != null) {
                    List<MeterReading> prevs = meterReadingRepository.findByRoomIdAndBillingMonth(contract.getRoomId(), moveOutDate.withDayOfMonth(1).minusMonths(1));
                    MeterReading lastReading = prevs.stream().filter(r -> r.getServiceUsageId().equals(usage.getId()) && r.getStatus() == MeterReading.MeterReadingStatus.APPROVED)
                        .findFirst().orElse(null);
                    BigDecimal oldReading = lastReading != null ? lastReading.getNewReading() : BigDecimal.ZERO;

                    ServicePricing pricing = servicePricingRepository.findCurrentByServiceId(service.getId(), moveOutDate).orElse(null);
                    List<ServiceTierPricing> tiers = pricing != null ? pricing.getTierPrices() : List.of();
                    
                    MeterReading newMr = new MeterReading();
                    newMr.setTenantId(contract.getTenantId());
                    newMr.setRoomId(contract.getRoomId());
                    newMr.setServiceUsageId(usage.getId());
                    newMr.setBillingMonth(moveOutDate.withDayOfMonth(1));
                    newMr.setOldReading(oldReading);
                    newMr.setNewReading(finalReading);
                    newMr.setConsumption(finalReading.subtract(oldReading).max(BigDecimal.ZERO));
                    newMr.setStatus(MeterReading.MeterReadingStatus.APPROVED);
                    UUID userToSet = SecurityUtils.getCurrentUserId();
                    if (userToSet == null) {
                        userToSet = contract.getCreatedBy();
                    }
                    newMr.setSubmittedBy(userToSet);
                    newMr.setApprovedBy(userToSet);
                    newMr.setCreatedAt(OffsetDateTime.now());
                    newMr.setUpdatedAt(OffsetDateTime.now());
                    generatedReadings.add(newMr);

                    BillingStrategy strategy = strategyFactory.getStrategy(service.getChargeType().name(), tiers != null && !tiers.isEmpty());
                    BigDecimal meterQuantity = finalReading.subtract(oldReading).max(BigDecimal.ZERO);
                    BillingContext ctx = new BillingContext(
                        service.getId(), service.getName(), service.getChargeType().name(),
                        oldReading, finalReading, meterQuantity, 1,
                        pricing != null ? pricing.getBasePrice() : BigDecimal.ZERO,
                        tiers.stream().map(t -> new BillingContext.PricingTier(t.getTierStart(), t.getTierEnd(), t.getPricePerUnit())).toList()
                    );
                    List<InvoiceDetail> det = strategy.calculate(ctx);
                    utilityDetails.addAll(det);
                    for (InvoiceDetail d : det) {
                        finalUtilities = finalUtilities.add(d.getLineTotal());
                    }
                }
            } else {
                ServicePricing pricing = servicePricingRepository.findCurrentByServiceId(service.getId(), moveOutDate).orElse(null);
                BillingStrategy strategy = strategyFactory.getStrategy(service.getChargeType().name(), false);
                BillingContext ctx = new BillingContext(
                    service.getId(), service.getName(), service.getChargeType().name(),
                    null, null, BigDecimal.valueOf(usage.getRegisteredQuantity() != null ? usage.getRegisteredQuantity() : 1),
                    1, pricing != null ? pricing.getBasePrice() : BigDecimal.ZERO, List.of()
                );
                List<InvoiceDetail> det = strategy.calculate(ctx);
                
                for (InvoiceDetail d : det) {
                    BigDecimal proRated = d.getLineTotal().multiply(BigDecimal.valueOf(daysLived)).divide(BigDecimal.valueOf(daysInMonth), 2, java.math.RoundingMode.HALF_UP);
                    d.setLineTotal(proRated);
                    finalUtilities = finalUtilities.add(proRated);
                    utilityDetails.add(d);
                }
            }
        }

        BigDecimal deposit = contract.getDepositAmount() != null ? contract.getDepositAmount() : BigDecimal.ZERO;
        List<Invoice> unpaidInvoices = invoiceRepository.findUnpaidByContractId(contract.getId());
        BigDecimal currentDebt = unpaidInvoices.stream()
            .map(inv -> inv.getTotalAmount()
                .subtract(inv.getPaidAmount() != null ? inv.getPaidAmount() : BigDecimal.ZERO)
                .subtract(inv.getBalanceDeduction() != null ? inv.getBalanceDeduction() : BigDecimal.ZERO))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal settlementTotal = proRatedRent.add(finalUtilities).add(repairFees);
        BigDecimal netAmount = deposit.subtract(currentDebt).subtract(settlementTotal);

        return new SettlementComputation(moveOutDate, proRatedRent, repairFees, finalUtilities, settlementTotal, currentDebt, deposit, netAmount, unpaidInvoices, damageDetails, utilityDetails, generatedReadings);
    }

    private InvoiceResult toInvoiceResult(Invoice invoice) {
        String roomNumber = null;
        if (invoice.getRoomId() != null) {
            roomNumber = roomRepository.findById(invoice.getRoomId())
                    .map(Room::getRoomNumber)
                    .orElse(null);
        }

        List<InvoiceDetailResult> detailResults = invoice.getDetails() != null
                ? invoice.getDetails().stream().map(d -> new InvoiceDetailResult(
                        d.getId(), d.getDescription(), d.getQuantity(), d.getUnitPrice(), d.getLineTotal(), d.getServiceId()
                  )).toList()
                : List.of();

        return new InvoiceResult(
            invoice.getId(),
            invoice.getContractId(),
            invoice.getRoomId(),
            roomNumber,
            invoice.getBillingMonth(),
            invoice.getTotalAmount(),
            invoice.getPaidAmount(),
            invoice.getBalanceDeduction(),
            invoice.getRemainingAmount(),
            BigDecimal.ZERO,
            getCurrentResidentBalance(invoice.getContractId()),
            invoice.getCalculationSnapshot(),
            invoice.getStatus() != null ? invoice.getStatus().name() : null,
            invoice.getInvoiceType() != null ? invoice.getInvoiceType().name() : null,
            invoice.getCancelReason(),
            invoice.getDueDate(),
            invoice.getCreatedAt(),
            detailResults
        );
    }

    private List<InvoiceDetailResult> toInvoiceDetailResults(List<InvoiceDetail> details) {
        return details.stream()
            .map(detail -> new InvoiceDetailResult(
                detail.getId(),
                detail.getDescription(),
                detail.getQuantity(),
                detail.getUnitPrice(),
                detail.getLineTotal(),
                detail.getServiceId()
            ))
            .toList();
    }

    private TransactionResult toTransactionResult(Transaction tx) {
        return new TransactionResult(
            tx.getId(),
            tx.getInvoiceId(),
            tx.getAmount(),
            tx.getOverpaidAmount(),
            tx.getCreditBalanceSnapshot() != null ? tx.getCreditBalanceSnapshot() : BigDecimal.ZERO,
            tx.getTransactionRef(),
            tx.getPaymentMethod() != null ? tx.getPaymentMethod().name() : null,
            tx.getBankCode(),
            tx.getStatus() != null ? tx.getStatus().name() : null,
            tx.getPaidAt()
        );
    }

    private BigDecimal getCurrentResidentBalance(Long contractId) {
        return contractRepository.findById(contractId)
            .map(c -> residentBalanceRepository.findById(c.getPrimaryResidentUserId())
                .map(rb -> rb.getBalance())
                .orElse(BigDecimal.ZERO))
            .orElse(BigDecimal.ZERO);
    }
}


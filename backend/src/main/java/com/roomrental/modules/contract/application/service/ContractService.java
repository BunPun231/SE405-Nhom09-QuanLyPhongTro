package com.roomrental.modules.contract.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.contract.application.event.ContractActivatedEvent;
import com.roomrental.modules.contract.application.event.ContractAdjustedEvent;
import com.roomrental.modules.contract.application.event.ContractCancelledEvent;
import com.roomrental.modules.contract.application.event.ContractCreatedEvent;
import com.roomrental.modules.contract.application.event.DepositCollectedEvent;
import com.roomrental.modules.contract.application.event.DepositDeductedEvent;
import com.roomrental.modules.contract.application.event.DepositRefundedEvent;
import com.roomrental.modules.contract.application.adjustment.ContractAdjustmentStrategy;
import com.roomrental.modules.contract.application.adjustment.ContractAdjustmentStrategyFactory;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import com.roomrental.modules.contract.application.dto.ContractAppendixResult;
import com.roomrental.modules.contract.application.dto.ContractCreateCommand;
import com.roomrental.modules.contract.application.dto.ContractDetailResult;
import com.roomrental.modules.contract.application.dto.ContractResult;
import com.roomrental.modules.contract.application.dto.ContractServiceItemCommand;
import com.roomrental.modules.contract.application.dto.ContractServiceItemResult;
import com.roomrental.modules.contract.application.event.ContractAdjustmentEvent;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.model.ContractAppendix;
import com.roomrental.modules.contract.domain.model.ContractResident;
import com.roomrental.modules.contract.domain.model.ContractServiceItem;
import com.roomrental.modules.contract.domain.repository.ContractAppendixRepository;
import com.roomrental.modules.contract.domain.repository.ContractResidentRepository;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.contract.domain.repository.ContractServiceItemRepository;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.resident.application.dto.ResidentCreateCommand;
import com.roomrental.modules.resident.application.service.ResidentService;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.model.ServiceUsage.ServiceUsageStatus;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.service.domain.model.ChargeType;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Application Service cho Contract Management.
 * Xử lý các use case liên quan đến hợp đồng.
 */
@Service
public class ContractService {
    private final ContractRepository contractRepository;
    private final ContractResidentRepository contractResidentRepository;
    private final ContractAppendixRepository contractAppendixRepository;
    private final ContractServiceItemRepository contractServiceItemRepository;
    private final RoomRepository roomRepository;
    private final MotelRepository motelRepository;
    private final com.roomrental.modules.resident.application.service.ResidentService residentService;
    private final ServiceUsageRepository serviceUsageRepository;
    private final RentalServiceRepository rentalServiceRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final ContractAdjustmentStrategyFactory strategyFactory;
    private final ApplicationEventPublisher eventPublisher;

    public ContractService(
            ContractRepository contractRepository,
            ContractResidentRepository contractResidentRepository,
            ContractAppendixRepository contractAppendixRepository,
            ContractServiceItemRepository contractServiceItemRepository,
            RoomRepository roomRepository,
            MotelRepository motelRepository,
            com.roomrental.modules.resident.application.service.ResidentService residentService,
            ServiceUsageRepository serviceUsageRepository,
            RentalServiceRepository rentalServiceRepository,
            MeterReadingRepository meterReadingRepository,
            ContractAdjustmentStrategyFactory strategyFactory,
            ApplicationEventPublisher eventPublisher
    ) {
        this.contractRepository = contractRepository;
        this.contractResidentRepository = contractResidentRepository;
        this.contractAppendixRepository = contractAppendixRepository;
        this.contractServiceItemRepository = contractServiceItemRepository;
        this.roomRepository = roomRepository;
        this.motelRepository = motelRepository;
        this.residentService = residentService;
        this.serviceUsageRepository = serviceUsageRepository;
        this.rentalServiceRepository = rentalServiceRepository;
        this.meterReadingRepository = meterReadingRepository;
        this.strategyFactory = strategyFactory;
        this.eventPublisher = eventPublisher;

    }

    @Transactional(rollbackFor = Exception.class)
    public ContractResult create(ContractCreateCommand command) {
        UUID tenantId = requireTenantId();
        UUID currentUserId = SecurityUtils.getCurrentUserId();
        
        // Validate input
        if (command.roomId() == null || command.roomId() <= 0) {
            throw BaseException.badRequest("roomId: must be valid");
        }
        if ((command.primaryResidentUserId() == null || command.primaryResidentUserId().isBlank())
                && (command.primaryResidentPhone() == null || command.primaryResidentPhone().isBlank())) {
            throw BaseException.badRequest("primaryResidentUserId or primaryResidentPhone: required");
        }
        if (command.rentPrice() == null || command.rentPrice().compareTo(BigDecimal.ZERO) <= 0) {
            throw BaseException.badRequest("rentPrice: must be positive");
        }
        if (command.startDate() == null || command.endDate() == null) {
            throw BaseException.badRequest("startDate and endDate: required");
        }
        if (!command.endDate().isAfter(command.startDate())) {
            throw BaseException.badRequest("endDate: must be after startDate");
        }
        if (command.depositAmount() == null || command.depositAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw BaseException.badRequest("depositAmount: must be positive");
        }

        Room room = roomRepository.findById(command.roomId())
                .orElseThrow(() -> BaseException.notFound("Room", command.roomId()));
        Long motelId = room.getMotelId();
        motelRepository.findByIdAndTenantId(motelId, tenantId)
            .orElseThrow(() -> BaseException.notFound("Motel", motelId));

        if (room.getStatus() != RoomStatus.EMPTY && room.getStatus() != RoomStatus.DEPOSITED) {
            throw BaseException.conflict("Room must be EMPTY or DEPOSITED to create contract");
        }
        if (contractRepository.existsActiveByRoomId(tenantId, room.getId())) {
            throw BaseException.conflict("Room already has an active contract");
        }

        UUID primaryResidentId = resolvePrimaryResident(tenantId, command);

        Contract.DepositStatus depositStatus = parseDepositStatus(command.depositStatus());
        boolean depositPaid = depositStatus == Contract.DepositStatus.PAID;

        Contract contract = new Contract();
        contract.setTenantId(tenantId);
        contract.setRoomId(command.roomId());
        contract.setPrimaryResidentUserId(primaryResidentId);
        contract.setRentPrice(command.rentPrice());
        contract.setStartDate(command.startDate());
        contract.setEndDate(command.endDate());
        contract.setDepositAmount(command.depositAmount());
        contract.setDepositStatus(depositStatus);
        contract.setStatus(depositPaid ? Contract.ContractStatus.ACTIVE : Contract.ContractStatus.DRAFT);
        
        contract.setBillingCycleDay(command.billingCycleDay() != null ? command.billingCycleDay() : 31);
        contract.setPaymentCycleMonths(command.paymentCycleMonths() != null ? command.paymentCycleMonths() : 1);
        
        LocalDate billingDate = command.billingDate();
        if (billingDate == null) {
            LocalDate start = command.startDate();
            int cycleDay = contract.getBillingCycleDay();
            if (cycleDay == 31) {
                billingDate = start.withDayOfMonth(start.lengthOfMonth());
            } else {
                int day = Math.min(cycleDay, start.lengthOfMonth());
                if (start.getDayOfMonth() <= day) {
                    billingDate = start.withDayOfMonth(day);
                } else {
                    LocalDate nextMonth = start.plusMonths(1);
                    int nextDay = Math.min(cycleDay, nextMonth.lengthOfMonth());
                    billingDate = nextMonth.withDayOfMonth(nextDay);
                }
            }
        }
        contract.setBillingDate(billingDate);
        contract.setCreatedAt(LocalDateTime.now());
        contract.setCreatedBy(currentUserId);

        Contract saved = contractRepository.save(contract);

        List<ContractResident> residents = buildResidents(saved.getId(), tenantId, primaryResidentId, command.residentUserIds());
        if (!residents.isEmpty()) {
            contractResidentRepository.saveAll(residents);
        }

        List<ContractServiceItem> serviceItems = buildServiceItems(saved.getId(), tenantId, motelId, command.serviceItems());
        if (!serviceItems.isEmpty()) {
            contractServiceItemRepository.saveAll(serviceItems);
        }

        if (depositPaid) {
            syncServiceUsages(room.getId(), serviceItems);
        }

        room.setStatus(depositPaid ? RoomStatus.RENTED : RoomStatus.DEPOSITED);
        room.setCurrentResidentsCount(residents.isEmpty() ? 1 : residents.size());
        roomRepository.save(room);

        ContractResult result = toResult(saved);
        eventPublisher.publishEvent(new ContractCreatedEvent(
                tenantId, currentUserId, SecurityUtils.getCurrentRole(),
                result.id(), result.status()));
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public ContractResult activate(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));

        if (!contract.getStatus().equals(Contract.ContractStatus.DRAFT)) {
            throw BaseException.badRequest("Only DRAFT contracts can be activated");
        }
        if (contract.getDepositStatus() != Contract.DepositStatus.PAID) {
            throw BaseException.badRequest("Deposit must be PAID before activation");
        }

        contract.activate();
        contract.setUpdatedAt(LocalDateTime.now());
        Contract saved = contractRepository.save(contract);

        Room room = roomRepository.findById(contract.getRoomId())
            .orElseThrow(() -> BaseException.notFound("Room", contract.getRoomId()));
        int residentsCount = contractResidentRepository.findByContractId(contract.getId()).size();
        room.setStatus(RoomStatus.RENTED);
        room.setCurrentResidentsCount(residentsCount > 0 ? residentsCount : 1);
        roomRepository.save(room);

        List<ContractServiceItem> serviceItems = contractServiceItemRepository.findByContractId(contract.getId());
        syncServiceUsages(room.getId(), serviceItems);

        ContractResult result = toResult(saved);
        eventPublisher.publishEvent(new ContractActivatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id()));
        return result;
    }


    @Transactional(readOnly = true)
    public Page<ContractResult> listByMotel(Long motelId, Pageable pageable) {
        UUID tenantId = requireTenantId();
        return contractRepository.findByTenantIdAndMotelId(tenantId, motelId, pageable)
                .map(this::toResult);
    }

    @Transactional(readOnly = true)
    public Page<ContractResult> listByMotelAndStatus(Long motelId, String status, Pageable pageable) {
        UUID tenantId = requireTenantId();
        return contractRepository.findByTenantIdAndMotelIdAndStatus(tenantId, motelId, status, pageable)
                .map(this::toResult);
    }

    @Transactional(readOnly = true)
    public Page<ContractResult> listExpiringByMotel(Long motelId, LocalDate fromDate, LocalDate toDate, Pageable pageable) {
        UUID tenantId = requireTenantId();
        return contractRepository.findExpiringByTenantIdAndMotelId(tenantId, motelId, fromDate, toDate, pageable)
                .map(this::toResult);
    }

    @Transactional(readOnly = true)
    public ContractResult getById(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));
        return toResult(contract);
    }

    @Transactional(readOnly = true)
    public ContractDetailResult getDetail(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));

        com.roomrental.modules.room.domain.model.Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
        Long motelId = room != null ? room.getMotelId() : null;

        List<String> residentIds = contractResidentRepository.findByContractId(id).stream()
                .map(r -> r.getResidentUserId().toString())
                .toList();
        List<ContractServiceItemResult> serviceItems = contractServiceItemRepository.findByContractId(id).stream()
                .map(item -> new ContractServiceItemResult(item.getServiceId(), item.getQuantity()))
                .toList();
        long appendicesCount = contractAppendixRepository.countByContractId(id);

        return new ContractDetailResult(
                contract.getId(),
                contract.getTenantId().toString(),
                contract.getRoomId(),
                motelId,
                contract.getPrimaryResidentUserId().toString(),
                contract.getRentPrice(),
                contract.getStartDate(),
                contract.getEndDate(),
                contract.getDepositAmount(),
                contract.getDepositStatus().toString(),
                contract.getStatus().toString(),
                contract.getBillingDate(),
                contract.getBillingCycleDay(),
                contract.getPaymentCycleMonths(),
                contract.getIntendedMoveOutDate(),
                contract.getPdfUrl(),
                contract.getCreatedAt(),
                contract.getUpdatedAt(),
                residentIds,
                serviceItems,
                (int) appendicesCount
        );
    }

    // ========================
    // Appendix queries (separate endpoints)
    // ========================

    @Transactional(readOnly = true)
    public Page<ContractAppendixResult> getAppendicesByContract(Long contractId, Pageable pageable) {
        UUID tenantId = requireTenantId();
        // Verify contract exists and belongs to tenant
        contractRepository.findByIdAndTenantId(contractId, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", contractId));

        return contractAppendixRepository.findByContractId(contractId, pageable)
                .map(this::toAppendixResult);
    }

    @Transactional(readOnly = true)
    public ContractAppendixResult getAppendixDetail(Long appendixId) {
        ContractAppendix appendix = contractAppendixRepository.findById(appendixId)
                .orElseThrow(() -> BaseException.notFound("ContractAppendix", appendixId));

        // Verify the parent contract belongs to the current tenant
        UUID tenantId = requireTenantId();
        contractRepository.findByIdAndTenantId(appendix.getContractId(), tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", appendix.getContractId()));

        return toAppendixResult(appendix);
    }

    @Transactional(readOnly = true)
    public byte[] exportPdf(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
            .orElseThrow(() -> BaseException.notFound("Contract", id));

        String text = "Contract " + contract.getId() + " | Room " + contract.getRoomId() +
            " | Start " + contract.getStartDate() + " | End " + contract.getEndDate();
        return buildSimplePdf(text);
    }

    @Transactional(readOnly = true)
    public List<ContractResult> listByTenant() {
        UUID tenantId = requireTenantId();
        return contractRepository.findByTenantId(tenantId).stream()
                .map(this::toResult)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ContractResult> listActiveByTenant() {
        UUID tenantId = requireTenantId();
        return contractRepository.findActiveByTenantId(tenantId).stream()
                .map(this::toResult)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ContractResult> listByResident(String residentUserId) {
        UUID tenantId = requireTenantId();
        UUID residentId = UUID.fromString(residentUserId);
        return contractRepository.findByResidentUserId(tenantId, residentId).stream()
                .map(this::toResult)
                .toList();
    }

    // ========================
    // UC66: Contract Adjustments
    // ========================

    @Transactional(rollbackFor = Exception.class)
    public ContractAppendixResult adjust(Long contractId, ContractAdjustmentRequest request) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UUID actorId = SecurityUtils.getCurrentUserId();
        Contract contract = contractRepository.findByIdAndTenantId(contractId, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", contractId));

        if (contract.getStatus() != Contract.ContractStatus.ACTIVE) {
            throw BaseException.badRequest("Only ACTIVE contracts can be adjusted");
        }

        ContractAdjustmentType type = parseAdjustmentType(request.type());
        ContractAdjustmentStrategy strategy = strategyFactory.getStrategy(type);
        Long appendixId = strategy.process(contract, request);

        contract.setUpdatedAt(LocalDateTime.now());
        contractRepository.save(contract);

        eventPublisher.publishEvent(new ContractAdjustmentEvent(
                contract.getId(),
                contract.getTenantId(),
                actorId,
                type,
                LocalDateTime.now()
        ));

        eventPublisher.publishEvent(new ContractAdjustedEvent(
                tenantId, actorId, SecurityUtils.getCurrentRole(),
                contractId, type.name()));

        // Build result from the created appendix, or return minimal result
        if (appendixId != null) {
            ContractAppendix appendix = contractAppendixRepository.findByContractId(contractId).stream()
                    .filter(a -> a.getId().equals(appendixId))
                    .findFirst()
                    .orElse(null);
            if (appendix != null) {
                return toAppendixResult(appendix);
            }
        }
        return new ContractAppendixResult(
                null, contract.getId(), null, null,
            type.name(), null, null,
            actorId.toString(), LocalDateTime.now()
        );
    }

    // ========================
    // UC67: Cancel Contract (soft delete)
    // ========================

    @Transactional(rollbackFor = Exception.class)
    public ContractResult cancel(Long id, String reason) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));

        if (contract.getStatus() == Contract.ContractStatus.CANCELED) {
            throw BaseException.badRequest("Contract is already canceled");
        }
        if (contract.getStatus() == Contract.ContractStatus.LIQUIDATED) {
            throw BaseException.badRequest("Cannot cancel a liquidated contract");
        }

        String oldStatus = contract.getStatus().name();
        contract.setStatus(Contract.ContractStatus.CANCELED);
        contract.setCancelReason(reason);
        contract.setUpdatedAt(LocalDateTime.now());

        Contract saved = contractRepository.save(contract);

        // Release room back to EMPTY or DEPOSITED
        Room room = roomRepository.findById(contract.getRoomId())
                .orElseThrow(() -> BaseException.notFound("Room", contract.getRoomId()));
        room.setStatus(RoomStatus.EMPTY);
        room.setCurrentResidentsCount(0);
        roomRepository.save(room);

        ContractResult result = toResult(saved);
        eventPublisher.publishEvent(new ContractCancelledEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldStatus, reason));
        return result;
    }

    // ========================
    // UC69: Deposit Management
    // ========================

    @Transactional(rollbackFor = Exception.class)
    public ContractResult collectDeposit(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));

        if (contract.getDepositStatus() != Contract.DepositStatus.UNPAID) {
            throw BaseException.badRequest("Deposit must be UNPAID to collect");
        }

        String oldDepositStatus = contract.getDepositStatus().name();
        contract.setDepositStatus(Contract.DepositStatus.PAID);
        contract.setUpdatedAt(LocalDateTime.now());

        // If DRAFT, auto-activate to ACTIVE once deposit is collected
        if (contract.getStatus() == Contract.ContractStatus.DRAFT) {
            contract.setStatus(Contract.ContractStatus.ACTIVE);
        }

        Contract saved = contractRepository.save(contract);

        // Update room status if contract becomes active
        if (saved.getStatus() == Contract.ContractStatus.ACTIVE) {
            Room room = roomRepository.findById(contract.getRoomId())
                    .orElseThrow(() -> BaseException.notFound("Room", contract.getRoomId()));
            int residentsCount = contractResidentRepository.findByContractId(contract.getId()).size();
            room.setStatus(RoomStatus.RENTED);
            room.setCurrentResidentsCount(residentsCount > 0 ? residentsCount : 1);
            roomRepository.save(room);

            List<ContractServiceItem> serviceItems = contractServiceItemRepository.findByContractId(contract.getId());
            syncServiceUsages(room.getId(), serviceItems);
        }

        ContractResult result = toResult(saved);
        eventPublisher.publishEvent(new DepositCollectedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldDepositStatus));
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public ContractResult refundDeposit(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));

        if (contract.getDepositStatus() != Contract.DepositStatus.PAID) {
            throw BaseException.badRequest("Deposit must be PAID to refund");
        }

        String oldDepositStatus = contract.getDepositStatus().name();
        contract.setDepositStatus(Contract.DepositStatus.REFUNDED);
        contract.setUpdatedAt(LocalDateTime.now());
        Contract saved = contractRepository.save(contract);

        ContractResult result = toResult(saved);
        eventPublisher.publishEvent(new DepositRefundedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldDepositStatus));
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public ContractResult deductDeposit(Long id) {
        UUID tenantId = requireTenantId();
        Contract contract = contractRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Contract", id));

        if (contract.getDepositStatus() != Contract.DepositStatus.PAID) {
            throw BaseException.badRequest("Deposit must be PAID to deduct");
        }

        String oldDepositStatus = contract.getDepositStatus().name();
        contract.setDepositStatus(Contract.DepositStatus.DEDUCTED);
        contract.setUpdatedAt(LocalDateTime.now());
        Contract saved = contractRepository.save(contract);

        ContractResult result = toResult(saved);
        eventPublisher.publishEvent(new DepositDeductedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldDepositStatus));
        return result;
    }

    // Helper methods
    private UUID requireTenantId() {
        return SecurityUtils.requireTenantId();
    }

    private ContractAdjustmentType parseAdjustmentType(String type) {
        if (type == null || type.isBlank()) {
            throw BaseException.badRequest("type: required");
        }
        try {
            return ContractAdjustmentType.valueOf(type);
        } catch (IllegalArgumentException ex) {
            throw BaseException.badRequest("type: invalid value");
        }
    }

    private UUID resolvePrimaryResident(UUID tenantId, ContractCreateCommand command) {
        if (command.primaryResidentUserId() != null && !command.primaryResidentUserId().isBlank()) {
            UUID residentId = UUID.fromString(command.primaryResidentUserId());
            residentService.get(residentId);
            return residentId;
        }

        if (command.primaryResidentPhone() == null || command.primaryResidentPhone().isBlank()) {
            throw BaseException.badRequest("primaryResidentPhone: required");
        }
        if (command.primaryResidentFullName() == null || command.primaryResidentFullName().isBlank()) {
            throw BaseException.badRequest("primaryResidentFullName: required");
        }
        if (command.primaryResidentIdCardNumber() == null || command.primaryResidentIdCardNumber().isBlank()) {
            throw BaseException.badRequest("primaryResidentIdCardNumber: required");
        }

        return residentService.create(new ResidentCreateCommand(
                command.primaryResidentPhone(),
                command.primaryResidentEmail(),
                command.primaryResidentFullName(),
                command.primaryResidentIdCardNumber(),
                command.primaryResidentIdCardFrontUrl(),
                command.primaryResidentIdCardBackUrl()
        )).userId();
    }

    private List<ContractResident> buildResidents(Long contractId, UUID tenantId, UUID primaryResidentId, List<String> residentUserIds) {
        List<ContractResident> residents = new java.util.ArrayList<>();
        ContractResident primary = new ContractResident();
        primary.setContractId(contractId);
        primary.setTenantId(tenantId);
        primary.setResidentUserId(primaryResidentId);
        primary.setActive(true);
        primary.setJoinedAt(LocalDateTime.now());
        residents.add(primary);

        if (residentUserIds != null) {
            for (String id : residentUserIds) {
                if (id == null || id.isBlank()) {
                    continue;
                }
                UUID residentId = UUID.fromString(id);
                if (residentId.equals(primaryResidentId)) {
                    continue;
                }
                ContractResident resident = new ContractResident();
                resident.setContractId(contractId);
                resident.setTenantId(tenantId);
                resident.setResidentUserId(residentId);
                resident.setActive(true);
                resident.setJoinedAt(LocalDateTime.now());
                residents.add(resident);
            }
        }

        return residents;
    }

    private Contract.DepositStatus parseDepositStatus(String status) {
        if (status == null || status.isBlank()) {
            return Contract.DepositStatus.UNPAID;
        }
        try {
            return Contract.DepositStatus.valueOf(status);
        } catch (IllegalArgumentException ex) {
            throw BaseException.badRequest("depositStatus: invalid value");
        }
    }

    private List<ContractServiceItem> buildServiceItems(
            Long contractId,
            UUID tenantId,
            Long motelId,
            List<ContractServiceItemCommand> serviceItems
    ) {
        List<ContractServiceItem> items = new java.util.ArrayList<>();
        List<Long> passedServiceIds = new java.util.ArrayList<>();

        if (serviceItems != null && !serviceItems.isEmpty()) {
            for (ContractServiceItemCommand item : serviceItems) {
                if (item == null || item.serviceId() == null) {
                    continue;
                }
                passedServiceIds.add(item.serviceId());

                RentalService service = rentalServiceRepository.findByIdAndMotelId(item.serviceId(), motelId)
                        .orElseThrow(() -> BaseException.notFound("Service", item.serviceId()));

                Integer quantity = item.quantity();
                if (service.getChargeType() == ChargeType.PER_QUANTITY) {
                    if (quantity == null || quantity < 1) {
                        throw BaseException.badRequest("quantity: required for PER_QUANTITY services");
                    }
                }

                ContractServiceItem serviceItem = new ContractServiceItem();
                serviceItem.setTenantId(tenantId);
                serviceItem.setContractId(contractId);
                serviceItem.setServiceId(item.serviceId());
                serviceItem.setQuantity(quantity != null ? quantity : 1);
                serviceItem.setStartIndex(item.startIndex());
                items.add(serviceItem);
            }
        }

        // Fetch all mandatory services for the motel and apply them if not already passed
        List<RentalService> mandatoryServices = rentalServiceRepository.findByMotelIdAndMandatory(motelId, true);
        for (RentalService service : mandatoryServices) {
            if (!passedServiceIds.contains(service.getId())) {
                ContractServiceItem serviceItem = new ContractServiceItem();
                serviceItem.setTenantId(tenantId);
                serviceItem.setContractId(contractId);
                serviceItem.setServiceId(service.getId());
                serviceItem.setQuantity(1);
                serviceItem.setStartIndex(null);
                items.add(serviceItem);
            }
        }

        return items;
    }

    private void syncServiceUsages(Long roomId, List<ContractServiceItem> serviceItems) {
        if (serviceItems == null || serviceItems.isEmpty()) {
            return;
        }

        for (ContractServiceItem item : serviceItems) {
            if (serviceUsageRepository.findActiveByRoomIdAndServiceId(roomId, item.getServiceId()).isPresent()) {
                continue;
            }

            ServiceUsage usage = new ServiceUsage();
            usage.setRoomId(roomId);
            usage.setServiceId(item.getServiceId());
            usage.setRegisteredQuantity(item.getQuantity() != null ? item.getQuantity() : 1);
            usage.setStatus(ServiceUsageStatus.ACTIVE);
            usage.setRegisteredAt(OffsetDateTime.now());
            usage.setUpdatedAt(OffsetDateTime.now());
            ServiceUsage savedUsage = serviceUsageRepository.save(usage);
            
            if (item.getStartIndex() != null) {
                MeterReading reading = new MeterReading();
                reading.setTenantId(SecurityUtils.requireTenantId());
                reading.setRoomId(roomId);
                reading.setServiceUsageId(savedUsage.getId());
                reading.setBillingMonth(LocalDate.now().withDayOfMonth(1));
                reading.setOldReading(item.getStartIndex());
                reading.setNewReading(item.getStartIndex());
                reading.setConsumption(BigDecimal.ZERO);
                reading.setStatus(MeterReading.MeterReadingStatus.APPROVED);
                reading.setApprovedBy(SecurityUtils.getCurrentUserId());
                reading.setCreatedAt(OffsetDateTime.now());
                reading.setUpdatedAt(OffsetDateTime.now());
                meterReadingRepository.save(reading);
            }
        }
    }

    private ContractAppendixResult toAppendixResult(ContractAppendix appendix) {
        return new ContractAppendixResult(
                appendix.getId(),
                appendix.getContractId(),
                appendix.getEffectiveDate(),
                appendix.getNewRentPrice(),
                appendix.getAppendixType(),
                appendix.getMetadata(),
                appendix.getNewServicePrices(),
                appendix.getCreatedBy() != null ? appendix.getCreatedBy().toString() : null,
                appendix.getCreatedAt()
        );
    }

    private byte[] buildSimplePdf(String text) {
        String safeText = text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
        String contentStream = "BT /F1 12 Tf 50 750 Td (" + safeText + ") Tj ET";
        byte[] contentBytes = contentStream.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);

        String obj1 = "1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n";
        String obj2 = "2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n";
        String obj3 = "3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] " +
                "/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n";
        String obj4 = "4 0 obj << /Length " + contentBytes.length + " >> stream\n" +
                contentStream + "\nendstream endobj\n";
        String obj5 = "5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n";

        StringBuilder sb = new StringBuilder();
        sb.append("%PDF-1.4\n");

        List<Integer> offsets = new java.util.ArrayList<>();
        offsets.add(sb.length());
        sb.append(obj1);
        offsets.add(sb.length());
        sb.append(obj2);
        offsets.add(sb.length());
        sb.append(obj3);
        offsets.add(sb.length());
        sb.append(obj4);
        offsets.add(sb.length());
        sb.append(obj5);

        int xrefOffset = sb.length();
        sb.append("xref\n0 6\n0000000000 65535 f \n");
        for (int offset : offsets) {
            sb.append(String.format("%010d 00000 n \n", offset));
        }
        sb.append("trailer << /Size 6 /Root 1 0 R >>\n");
        sb.append("startxref\n");
        sb.append(xrefOffset).append("\n%%EOF");

        return sb.toString().getBytes(java.nio.charset.StandardCharsets.ISO_8859_1);
    }

    private ContractResult toResult(Contract contract) {
        return new ContractResult(
                contract.getId(),
                contract.getTenantId().toString(),
                contract.getRoomId(),
                contract.getPrimaryResidentUserId().toString(),
                contract.getRentPrice(),
                contract.getStartDate(),
                contract.getEndDate(),
                contract.getDepositAmount(),
                contract.getDepositStatus().toString(),
                contract.getStatus().toString(),
                contract.getBillingDate(),
                contract.getBillingCycleDay(),
                contract.getPaymentCycleMonths(),
                contract.getIntendedMoveOutDate(),
                contract.getPdfUrl(),
                contract.getCreatedAt(),
                contract.getUpdatedAt()
        );
    }
}
package com.roomrental.modules.finance.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.finance.application.dto.*;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.modules.finance.application.event.*;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.finance.interfaces.rest.dto.InvoicePaymentInfoResult;
import com.roomrental.modules.finance.application.strategy.BillingContext;
import com.roomrental.modules.finance.application.strategy.BillingStrategy;
import com.roomrental.modules.finance.application.strategy.BillingStrategyFactory;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.model.Invoice.InvoiceStatus;
import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.finance.domain.repository.InvoiceDetailRepository;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.repository.ResidentBalanceRepository;
import com.roomrental.modules.finance.domain.repository.TransactionRepository;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.contract.domain.repository.ContractServiceItemRepository;
import com.roomrental.modules.contract.domain.model.ContractServiceItem;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.service.domain.model.ServicePricing;
import com.roomrental.modules.service.domain.model.ServiceTierPricing;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
public class InvoiceService {
    private static final Logger log = LoggerFactory.getLogger(InvoiceService.class);
    
    private final InvoiceRepository invoiceRepository;
    private final InvoiceDetailRepository invoiceDetailRepository;
    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final RentalServiceRepository rentalServiceRepository;
    private final ServiceUsageRepository serviceUsageRepository;
    private final ServicePricingRepository servicePricingRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final ResidentBalanceRepository residentBalanceRepository;
    private final BillingStrategyFactory strategyFactory;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper objectMapper;
    private final MotelRepository motelRepository;
    private final ContractServiceItemRepository contractServiceItemRepository;
    private final TransactionRepository transactionRepository;

    private static final String SKIP_ALREADY_INVOICED = "Đã có hóa đơn cho kỳ này";
    private static final String SKIP_MISSING_READING = "Thiếu chỉ số điện/nước đã duyệt (APPROVED)";

    public InvoiceService(
            InvoiceRepository invoiceRepository,
            InvoiceDetailRepository invoiceDetailRepository,
            ContractRepository contractRepository,
            RoomRepository roomRepository,
            RentalServiceRepository rentalServiceRepository,
            ServiceUsageRepository serviceUsageRepository,
            ServicePricingRepository servicePricingRepository,
            MeterReadingRepository meterReadingRepository,
            ResidentBalanceRepository residentBalanceRepository,
            BillingStrategyFactory strategyFactory,
            ApplicationEventPublisher eventPublisher,
            ObjectMapper objectMapper,
            MotelRepository motelRepository,
            ContractServiceItemRepository contractServiceItemRepository,
            TransactionRepository transactionRepository) {
        this.invoiceRepository = invoiceRepository;
        this.invoiceDetailRepository = invoiceDetailRepository;
        this.contractRepository = contractRepository;
        this.roomRepository = roomRepository;
        this.rentalServiceRepository = rentalServiceRepository;
        this.serviceUsageRepository = serviceUsageRepository;
        this.servicePricingRepository = servicePricingRepository;
        this.meterReadingRepository = meterReadingRepository;
        this.residentBalanceRepository = residentBalanceRepository;
        this.strategyFactory = strategyFactory;
        this.eventPublisher = eventPublisher;
        this.objectMapper = objectMapper;
        this.motelRepository = motelRepository;
        this.contractServiceItemRepository = contractServiceItemRepository;
        this.transactionRepository = transactionRepository;
    }

    @Async("taskExecutor")
    @Transactional(rollbackFor = Exception.class)
    public CompletableFuture<Void> generateForMotel(InvoiceGenerateCommand command) {
        log.info("Starting async invoice generation for motelId={}, billingMonth={}", command.motelId(), command.billingMonth());
        try {
            runGeneration(command);
            return CompletableFuture.completedFuture(null);
        } catch (Exception ex) {
            log.error("Async invoice generation failed for motelId={}, billingMonth={}", command.motelId(), command.billingMonth(), ex);
            throw ex;
        }
    }

    /**
     * UC73 - chạy đồng bộ để Quản lý nhận ngay kết quả: số hóa đơn đã tạo và các phòng bị bỏ qua.
     * Idempotent: phòng đã có hóa đơn trong kỳ được bỏ qua (BR73.2).
     */
    @Transactional(rollbackFor = Exception.class)
    public InvoiceGenerationResult generateForMotelNow(InvoiceGenerateCommand command) {
        return runGeneration(command);
    }

    private InvoiceGenerationResult runGeneration(InvoiceGenerateCommand command) {
        LocalDate billingMonth = command.billingMonth().withDayOfMonth(1);
        List<InvoiceResult> results = new ArrayList<>();
        List<SkippedInvoiceRoomResult> skippedRooms = new ArrayList<>();
        List<Room> rooms = roomRepository.findByMotelId(command.motelId(), Pageable.unpaged()).getContent();

        for (Room room : rooms) {
            List<Contract> contracts = contractRepository.findByRoomId(room.getId()).stream()
                    .filter(Contract::isActive)
                    .toList();
            if (contracts.isEmpty()) {
                continue;
            }

            Contract contract = contracts.get(0);

            // Check duplicate (BR73.2 - idempotent)
            if (invoiceRepository.existsByContractIdAndBillingMonth(contract.getId(), billingMonth)) {
                skippedRooms.add(new SkippedInvoiceRoomResult(room.getId(), room.getRoomNumber(), SKIP_ALREADY_INVOICED));
                continue;
            }

            try {
                InvoiceResult res = generateForSingleContract(contract, billingMonth);
                if (res != null) {
                    results.add(res);
                } else {
                    skippedRooms.add(new SkippedInvoiceRoomResult(
                        room.getId(), room.getRoomNumber(), SKIP_MISSING_READING));
                }
            } catch (Exception ex) {
                log.error("Failed to generate invoice in motel loop for contractId={}", contract.getId(), ex);
                skippedRooms.add(new SkippedInvoiceRoomResult(
                    room.getId(), room.getRoomNumber(), "Lỗi: " + ex.getMessage()));
            }
        }

        log.info("Completed invoice generation for motelId={}, billingMonth={}, created={}, skipped={}, skippedRooms={}",
                command.motelId(), billingMonth, results.size(), skippedRooms.size(),
                skippedRooms.stream().map(r -> r.roomNumber() + ":" + r.reason()).toList());
        return new InvoiceGenerationResult(results, skippedRooms);
    }

    @Transactional(rollbackFor = Exception.class)
    public InvoiceResult generateForSingleContract(Contract contract, LocalDate billingMonth) {
        return generateInvoice(contract, billingMonth, List.of(), null);
    }

    /**
     * Sinh một hóa đơn cho hợp đồng. {@code extraLines} là các dòng phụ thu / giảm trừ (UC76),
     * {@code replacesInvoiceId} là hóa đơn bị hủy mà hóa đơn này tái cấp.
     */
    private InvoiceResult generateInvoice(Contract contract, LocalDate billingMonth,
                                          List<InvoiceDetail> extraLines, Long replacesInvoiceId) {
        UUID tenantId = contract.getTenantId();
        Room room = roomRepository.findById(contract.getRoomId())
                .orElseThrow(() -> BaseException.notFound("Room", contract.getRoomId()));

        List<ContractServiceItem> contractServices = contractServiceItemRepository.findByContractId(contract.getId());
        java.util.Set<Long> registeredServiceIds = contractServices.stream()
                .map(ContractServiceItem::getServiceId)
                .collect(Collectors.toSet());
        List<ServiceUsage> billableUsages = serviceUsageRepository.findBillableByRoomId(room.getId()).stream()
                .filter(usage -> registeredServiceIds.contains(usage.getServiceId()))
                .collect(Collectors.toList());
        Map<Long, MeterReading> approvedReadings = meterReadingRepository.findByRoomIdAndBillingMonth(room.getId(), billingMonth)
                .stream()
                .filter(r -> r.getStatus() == MeterReading.MeterReadingStatus.APPROVED)
                .collect(Collectors.toMap(MeterReading::getServiceUsageId, reading -> reading, (left, right) -> left));

        boolean missingIndexReading = billableUsages.stream().anyMatch(usage -> {
            RentalService service = rentalServiceRepository.findByIdAndMotelId(usage.getServiceId(), room.getMotelId()).orElse(null);
            return service != null && (
                service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.PER_INDEX
                || service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.METERED)
                    && !approvedReadings.containsKey(usage.getId());
        });

        if (missingIndexReading) {
            return null;
        }

        Invoice invoice = new Invoice();
        invoice.setTenantId(tenantId);
        invoice.setContractId(contract.getId());
        invoice.setRoomId(contract.getRoomId());
        invoice.setBillingMonth(billingMonth);
        invoice.setDueDate(LocalDate.now().plusDays(5)); // default 5 days
        invoice.setCreatedAt(OffsetDateTime.now());
        invoice.setUpdatedAt(OffsetDateTime.now());

        List<Map<String, Object>> snapshotItems = new ArrayList<>();
        
        // 1. Calculate Rent
        BillingStrategy rentStrategy = strategyFactory.getStrategy("FIXED", false);
        BillingContext rentContext = new BillingContext(
            null, "Tiền phòng", "FIXED", null, null, null, 1, contract.getRentPrice(), null
        );
        snapshotItems.add(buildSnapshotItem("FIXED", false, rentContext));
        List<InvoiceDetail> details = new ArrayList<>(rentStrategy.calculate(rentContext));

        // 2. Calculate services from real service usages
        for (ServiceUsage usage : billableUsages) {
            RentalService service = rentalServiceRepository.findByIdAndMotelId(usage.getServiceId(), room.getMotelId())
                    .orElseThrow(() -> BaseException.notFound("Service", usage.getServiceId()));
            LocalDate pricingDate = billingMonth.withDayOfMonth(billingMonth.lengthOfMonth());
            ServicePricing pricing = servicePricingRepository.findCurrentByServiceId(service.getId(), pricingDate).orElse(null);
            List<ServiceTierPricing> tiers = pricing != null ? pricing.getTierPrices() : List.of();
            boolean hasTiers = tiers != null && !tiers.isEmpty();

            MeterReading approvedReading = approvedReadings.get(usage.getId());
            BillingStrategy strategy = strategyFactory.getStrategy(service.getChargeType().name(), hasTiers);
            BillingContext context = buildBillingContext(service, usage, room, contract, pricing, tiers, approvedReading);
            snapshotItems.add(buildSnapshotItem(service.getChargeType().name(), hasTiers, context));
            details.addAll(strategy.calculate(context));
        }

        for (InvoiceDetail extra : extraLines) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("strategyCode", "ADJUSTMENT");
            item.put("hasTiers", false);
            item.put("serviceId", null);
            item.put("serviceName", extra.getDescription());
            item.put("chargeType", "ADJUSTMENT");
            item.put("quantity", BigDecimal.ONE);
            item.put("basePrice", extra.getLineTotal());
            snapshotItems.add(item);
            details.add(extra);
        }

        BigDecimal total = details.stream().map(InvoiceDetail::getLineTotal).reduce(BigDecimal.ZERO, BigDecimal::add)
                .setScale(0, RoundingMode.HALF_UP);
        if (total.compareTo(BigDecimal.ZERO) < 0) {
            // BR73.10: số tiền hóa đơn không được âm
            throw BaseException.badRequest("Tổng tiền hóa đơn sau điều chỉnh không được âm");
        }
        invoice.setTotalAmount(total);
        
        // 3. Apply auto-pay from balance if any
        UUID residentId = contract.getPrimaryResidentUserId();
        com.roomrental.modules.finance.domain.model.ResidentBalance residentBalance = residentBalanceRepository.findById(residentId)
            .orElseGet(() -> {
                com.roomrental.modules.finance.domain.model.ResidentBalance rb = new com.roomrental.modules.finance.domain.model.ResidentBalance();
                rb.setResidentUserId(residentId);
                return rb;
            });
        BigDecimal creditBalance = residentBalance.getBalance() != null ? residentBalance.getBalance() : BigDecimal.ZERO;
        BigDecimal deduction = BigDecimal.ZERO;

        if (creditBalance.compareTo(BigDecimal.ZERO) > 0) {
            if (creditBalance.compareTo(total) >= 0) {
                deduction = total;
                residentBalance.deductBalance(total);
            } else {
                deduction = creditBalance;
                residentBalance.setBalance(BigDecimal.ZERO);
            }
            residentBalanceRepository.save(residentBalance);
        }

        invoice.setBalanceDeduction(deduction);
        invoice.setPaidAmount(BigDecimal.ZERO);
        if (invoice.getRemainingAmount().compareTo(BigDecimal.ZERO) <= 0) {
            invoice.setStatus(InvoiceStatus.PAID);
        }

        InvoiceGenerateCommand fakeCommand = new InvoiceGenerateCommand(room.getMotelId(), billingMonth);
        invoice.setCalculationSnapshot(buildCalculationSnapshot(fakeCommand, contract, room, snapshotItems, replacesInvoiceId));
        
        Invoice saved = invoiceRepository.save(invoice);
        
        for (InvoiceDetail d : details) {
            d.setInvoiceId(saved.getId());
        }
        invoiceDetailRepository.saveAll(details);

        List<ServiceUsage> toCancel = billableUsages.stream()
                .filter(usage -> usage.getStatus() == ServiceUsage.ServiceUsageStatus.PENDING_CANCELLATION)
                .peek(usage -> usage.setStatus(ServiceUsage.ServiceUsageStatus.CANCELLED))
                .peek(usage -> usage.setUpdatedAt(OffsetDateTime.now()))
                .collect(Collectors.toList());
        if (!toCancel.isEmpty()) {
            serviceUsageRepository.saveAll(toCancel);
        }
        
        UUID actorId = null;
        String actorRole = null;
        try {
            actorId = SecurityUtils.getCurrentUserId();
            actorRole = SecurityUtils.getCurrentRole();
        } catch (Exception ignored) {}

        eventPublisher.publishEvent(new InvoiceCreatedEvent(
            tenantId, actorId, actorRole,
            saved.getId(), saved.getTotalAmount().toPlainString()
        ));
        
        return toResult(saved);
    }

    @Transactional(readOnly = true)
    public Page<InvoiceResult> list(Long motelId, String status, Pageable pageable) {
        return list(motelId, status, null, null, pageable);
    }

    /** UC74 - Quản lý: lọc theo khu trọ, trạng thái, kỳ (yyyy-MM) và phòng; mặc định kỳ mới nhất trước (BR74.4). */
    @Transactional(readOnly = true)
    public Page<InvoiceResult> list(Long motelId, String status, String billingMonth, Long roomId, Pageable pageable) {
        UUID tenantId = SecurityUtils.requireTenantId();
        LocalDate month = parseBillingMonth(billingMonth);
        Pageable sorted = withDefaultSort(pageable);
        boolean hasStatus = status != null && !status.isEmpty();
        if (motelId != null) {
            Page<Contract> contractsPage = contractRepository.findByTenantIdAndMotelId(tenantId, motelId, Pageable.unpaged());
            List<Long> contractIds = contractsPage.getContent().stream()
                .map(Contract::getId)
                .collect(Collectors.toList());
            if (contractIds.isEmpty()) {
                return Page.empty(pageable);
            }
            return filteredPage(p -> hasStatus
                    ? invoiceRepository.findByTenantIdAndContractIdInAndStatus(tenantId, contractIds, status, p)
                    : invoiceRepository.findByTenantIdAndContractIdIn(tenantId, contractIds, p),
                    month, roomId, sorted);
        }

        return filteredPage(p -> hasStatus
                ? invoiceRepository.findByTenantIdAndStatus(tenantId, status, p)
                : invoiceRepository.findByTenantId(tenantId, p),
                month, roomId, sorted);
    }

    @Transactional(readOnly = true)
    public Page<InvoiceResult> listMyInvoices(String status, Pageable pageable) {
        return listMyInvoices(status, null, pageable);
    }

    /** UC74 - Khách thuê: chỉ thấy hóa đơn của hợp đồng mình là người đại diện (BR74.2). */
    @Transactional(readOnly = true)
    public Page<InvoiceResult> listMyInvoices(String status, String billingMonth, Pageable pageable) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UUID userId = SecurityUtils.getCurrentUserId();
        LocalDate month = parseBillingMonth(billingMonth);

        List<Long> contractIds = contractRepository.findByTenantId(tenantId).stream()
            .filter(c -> c.getPrimaryResidentUserId() != null && c.getPrimaryResidentUserId().equals(userId))
            .map(Contract::getId)
            .collect(Collectors.toList());

        if (contractIds.isEmpty()) {
            return Page.empty(pageable);
        }

        boolean hasStatus = status != null && !status.isEmpty();
        return filteredPage(p -> hasStatus
                ? invoiceRepository.findByTenantIdAndContractIdInAndStatus(tenantId, contractIds, status, p)
                : invoiceRepository.findByTenantIdAndContractIdIn(tenantId, contractIds, p),
                month, null, withDefaultSort(pageable));
    }

    private Page<InvoiceResult> filteredPage(java.util.function.Function<Pageable, Page<Invoice>> query,
                                             LocalDate month, Long roomId, Pageable pageable) {
        if (month == null && roomId == null) {
            return query.apply(pageable).map(this::toResult);
        }
        List<Invoice> all = query.apply(Pageable.unpaged()).getContent().stream()
                .filter(i -> month == null || (i.getBillingMonth() != null
                        && i.getBillingMonth().getYear() == month.getYear()
                        && i.getBillingMonth().getMonthValue() == month.getMonthValue()))
                .filter(i -> roomId == null || roomId.equals(i.getRoomId()))
                .sorted(Comparator.comparing(Invoice::getBillingMonth, Comparator.nullsLast(Comparator.reverseOrder()))
                        .thenComparing(Invoice::getId, Comparator.nullsLast(Comparator.reverseOrder())))
                .toList();
        if (pageable.isUnpaged()) {
            return new PageImpl<>(all.stream().map(this::toResult).toList());
        }
        int from = (int) Math.min(pageable.getOffset(), all.size());
        int to = Math.min(from + pageable.getPageSize(), all.size());
        List<InvoiceResult> content = all.subList(from, to).stream().map(this::toResult).toList();
        return new PageImpl<>(content, pageable, all.size());
    }

    private static Pageable withDefaultSort(Pageable pageable) {
        if (pageable == null || pageable.isUnpaged()) {
            return pageable == null ? Pageable.unpaged() : pageable;
        }
        if (pageable.getSort().isSorted()) {
            return pageable;
        }
        return PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(),
                Sort.by(Sort.Order.desc("billingMonth"), Sort.Order.desc("id")));
    }

    /** Nhận "yyyy-MM" hoặc "yyyy-MM-dd"; trả về ngày đầu tháng hoặc null. */
    static LocalDate parseBillingMonth(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String v = raw.trim();
        try {
            if (v.length() == 7) {
                return LocalDate.parse(v + "-01");
            }
            return LocalDate.parse(v).withDayOfMonth(1);
        } catch (Exception ex) {
            throw BaseException.badRequest("Kỳ hóa đơn không hợp lệ, định dạng yyyy-MM: " + raw);
        }
    }

    @Transactional(readOnly = true)
    public java.math.BigDecimal getMyBalance() {
        UUID userId = SecurityUtils.getCurrentUserId();
        return residentBalanceRepository.findById(userId)
            .map(rb -> rb.getBalance() != null ? rb.getBalance() : java.math.BigDecimal.ZERO)
            .orElse(java.math.BigDecimal.ZERO);
    }

    @Transactional(readOnly = true)
    public java.math.BigDecimal getResidentBalance(UUID residentId) {
        return residentBalanceRepository.findById(residentId)
            .map(rb -> rb.getBalance() != null ? rb.getBalance() : java.math.BigDecimal.ZERO)
            .orElse(java.math.BigDecimal.ZERO);
    }

    @Transactional(readOnly = true)
    public Map<UUID, java.math.BigDecimal> getResidentBalances(List<UUID> residentIds) {
        if (residentIds == null || residentIds.isEmpty()) {
            return java.util.Collections.emptyMap();
        }
        return residentIds.stream().collect(Collectors.toMap(
            id -> id,
            id -> residentBalanceRepository.findById(id)
                .map(rb -> rb.getBalance() != null ? rb.getBalance() : java.math.BigDecimal.ZERO)
                .orElse(java.math.BigDecimal.ZERO)
        ));
    }



    @Transactional(readOnly = true)
    public InvoiceResult getDetail(Long id) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Invoice invoice = invoiceRepository.findByIdAndTenantId(id, tenantId)
            .orElseThrow(() -> BaseException.notFound("Invoice", id));
        List<InvoiceDetail> details = invoiceDetailRepository.findByInvoiceId(id);
        invoice.setDetails(details);
        return toResult(invoice);
    }

    /**
     * UC76 - Hủy và tái cấp hóa đơn sai sót. Hóa đơn cũ chuyển VOID (giữ nguyên số tiền để kiểm toán - BR76.2),
     * chỉ số điện nước đúng được đồng bộ (BR76.5) và một hóa đơn mới được sinh ra (BR76.6).
     * Trả về hóa đơn MỚI.
     */
    @Transactional(rollbackFor = Exception.class)
    public InvoiceResult adjustInvoice(InvoiceAdjustCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Invoice invoice = invoiceRepository.findByIdAndTenantId(command.invoiceId(), tenantId)
            .orElseThrow(() -> BaseException.notFound("Invoice", command.invoiceId()));

        if (command.reason() == null || command.reason().isBlank()) {
            throw BaseException.badRequest("Vui lòng nhập lý do hủy và tái cấp hóa đơn");
        }
        boolean hasPayment = invoice.getPaidAmount() != null && invoice.getPaidAmount().compareTo(BigDecimal.ZERO) > 0;
        if (!invoice.canBeVoided() || hasPayment || transactionRepository.existsByInvoiceId(invoice.getId())) {
            throw BaseException.badRequest("Không thể hủy hóa đơn đã có giao dịch. Vui lòng sử dụng tính năng Khấu trừ vào kỳ sau");
        }

        Contract contract = contractRepository.findById(invoice.getContractId())
            .orElseThrow(() -> BaseException.notFound("Contract", invoice.getContractId()));

        // 1. Đồng bộ chỉ số điện/nước đúng (key = serviceId)
        syncCorrectedReadings(invoice, command.correctedReadings());

        // 2. Tính các dòng điều chỉnh
        List<InvoiceDetail> extraLines = new ArrayList<>();
        if (command.customAdjustments() != null && !command.customAdjustments().isEmpty()) {
            Map<Long, InvoiceDetail> oldDetails = new HashMap<>();
            for (InvoiceDetail d : invoiceDetailRepository.findByInvoiceId(invoice.getId())) {
                oldDetails.put(d.getId(), d);
            }
            command.customAdjustments().forEach((detailId, newAmount) -> {
                InvoiceDetail old = oldDetails.get(detailId);
                if (old == null || newAmount == null) {
                    throw BaseException.badRequest("Dòng hóa đơn cần sửa không hợp lệ: " + detailId);
                }
                BigDecimal delta = newAmount.subtract(old.getLineTotal() != null ? old.getLineTotal() : BigDecimal.ZERO);
                if (delta.signum() != 0) {
                    extraLines.add(adjustmentLine("Điều chỉnh " + old.getDescription(), delta));
                }
            });
        }
        if (command.adjustments() != null) {
            for (InvoiceAdjustCommand.AdjustmentLine line : command.adjustments()) {
                if (line == null || line.amount() == null || line.amount().signum() == 0) {
                    continue;
                }
                if (line.description() == null || line.description().isBlank()) {
                    throw BaseException.badRequest("Khoản phụ thu/giảm trừ phải có mô tả");
                }
                String prefix = line.amount().signum() > 0 ? "Phụ thu: " : "Giảm trừ: ";
                extraLines.add(adjustmentLine(prefix + line.description().trim(), line.amount()));
            }
        }

        // 3. Hoàn lại tiền đã khấu trừ từ số dư của hóa đơn cũ (sẽ khấu trừ lại khi sinh hóa đơn mới)
        restoreBalanceDeduction(invoice, contract);

        // 4. Hủy hóa đơn cũ
        BigDecimal oldTotal = invoice.getTotalAmount();
        invoice.setStatus(InvoiceStatus.VOID);
        invoice.setCancelReason(command.reason().trim());
        invoice.setUpdatedAt(OffsetDateTime.now());
        invoiceRepository.save(invoice);

        // 5. Sinh hóa đơn mới
        InvoiceResult reissued = generateInvoice(contract, invoice.getBillingMonth(), extraLines, invoice.getId());
        if (reissued == null) {
            throw BaseException.badRequest("Không thể tái cấp: phòng còn thiếu chỉ số điện/nước đã duyệt cho kỳ này");
        }

        log.info("AUDIT invoice reissued: actor={}, oldInvoiceId={}, newInvoiceId={}, oldTotal={}, newTotal={}, reason={}",
                SecurityUtils.getCurrentUserId(), invoice.getId(), reissued.id(), oldTotal, reissued.totalAmount(), command.reason());

        eventPublisher.publishEvent(new InvoiceCancelledEvent(
            tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
            invoice.getId(),
            command.reason().trim() + " (Đã tái cấp hóa đơn mới #" + reissued.id() + ")"
        ));

        return getDetail(reissued.id());
    }

    private void syncCorrectedReadings(Invoice invoice, Map<Long, BigDecimal> correctedReadings) {
        if (correctedReadings == null || correctedReadings.isEmpty()) {
            return;
        }
        Map<Long, Long> serviceIdByUsage = serviceUsageRepository.findByRoomId(invoice.getRoomId()).stream()
                .collect(Collectors.toMap(ServiceUsage::getId, ServiceUsage::getServiceId, (a, b) -> a));
        List<MeterReading> readings = meterReadingRepository.findByRoomIdAndBillingMonth(invoice.getRoomId(), invoice.getBillingMonth())
                .stream()
                .filter(r -> r.getStatus() == MeterReading.MeterReadingStatus.APPROVED)
                .toList();
        java.util.Set<Long> applied = new java.util.HashSet<>();
        for (MeterReading reading : readings) {
            Long serviceId = serviceIdByUsage.get(reading.getServiceUsageId());
            if (serviceId == null || !correctedReadings.containsKey(serviceId) || applied.contains(serviceId)) {
                continue;
            }
            BigDecimal newValue = correctedReadings.get(serviceId);
            if (newValue == null) {
                continue;
            }
            if (reading.getOldReading() != null && newValue.compareTo(reading.getOldReading()) < 0) {
                throw BaseException.badRequest("Chỉ số mới không được nhỏ hơn chỉ số cũ (" + reading.getOldReading().toPlainString() + ")");
            }
            reading.setNewReading(newValue);
            reading.calculateConsumption();
            reading.setUpdatedAt(OffsetDateTime.now());
            meterReadingRepository.save(reading);
            applied.add(serviceId);
        }
        for (Long serviceId : correctedReadings.keySet()) {
            if (!applied.contains(serviceId)) {
                throw BaseException.badRequest("Không tìm thấy chỉ số đã duyệt của dịch vụ " + serviceId + " trong kỳ này");
            }
        }
    }

    private static InvoiceDetail adjustmentLine(String description, BigDecimal amount) {
        return new InvoiceDetail(description, BigDecimal.ONE, amount, null);
    }

    /** BR77.8: hoàn lại phần đã khấu trừ từ số dư của khách. */
    private void restoreBalanceDeduction(Invoice invoice, Contract contract) {
        BigDecimal deduction = invoice.getBalanceDeduction();
        if (deduction == null || deduction.signum() <= 0 || contract == null || contract.getPrimaryResidentUserId() == null) {
            return;
        }
        UUID residentId = contract.getPrimaryResidentUserId();
        com.roomrental.modules.finance.domain.model.ResidentBalance rb = residentBalanceRepository.findById(residentId)
            .orElseGet(() -> {
                com.roomrental.modules.finance.domain.model.ResidentBalance created = new com.roomrental.modules.finance.domain.model.ResidentBalance();
                created.setResidentUserId(residentId);
                return created;
            });
        rb.addBalance(deduction);
        residentBalanceRepository.save(rb);
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteInvoice(Long id) {
        deleteInvoice(id, null);
    }

    /** UC77 - xóa mềm hóa đơn PENDING chưa có giao dịch; giữ nguyên chỉ số điện nước (BR77.5). */
    @Transactional(rollbackFor = Exception.class)
    public void deleteInvoice(Long id, String reason) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Invoice invoice = invoiceRepository.findByIdAndTenantId(id, tenantId)
            .orElseThrow(() -> BaseException.notFound("Invoice", id));

        if (!invoice.canBeDeleted() || transactionRepository.existsByInvoiceId(id)) {
            throw BaseException.badRequest("Không thể xóa hóa đơn đã phát sinh thanh toán, vui lòng thực hiện hoàn tiền hoặc điều chỉnh");
        }

        contractRepository.findById(invoice.getContractId())
            .ifPresent(contract -> restoreBalanceDeduction(invoice, contract));

        if (reason != null && !reason.isBlank()) {
            invoice.setCancelReason(reason.trim());
            invoice.setUpdatedAt(OffsetDateTime.now());
            invoiceRepository.save(invoice);
        }
        invoiceRepository.softDelete(id);

        log.info("AUDIT invoice deleted: actor={}, invoiceId={}, totalBeforeDelete={}, reason={}",
                SecurityUtils.getCurrentUserId(), id, invoice.getTotalAmount(), reason);

        eventPublisher.publishEvent(new InvoiceDeletedEvent(
            tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(), id
        ));
    }

    private InvoiceResult toResult(Invoice invoice) {
        BigDecimal creditBalanceSnapshot = BigDecimal.ZERO;
        if (invoice.getContractId() != null) {
            contractRepository.findById(invoice.getContractId()).ifPresent(contract -> {
                com.roomrental.modules.finance.domain.model.ResidentBalance rb = residentBalanceRepository.findById(contract.getPrimaryResidentUserId()).orElse(null);
                if (rb != null && rb.getBalance() != null) {
                    // Update this snapshot to what rb says
                }
            });
        }
        creditBalanceSnapshot = contractRepository.findById(invoice.getContractId())
                .flatMap(c -> residentBalanceRepository.findById(c.getPrimaryResidentUserId()))
                .map(rb -> rb.getBalance())
                .orElse(BigDecimal.ZERO);

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
            BigDecimal.ZERO, // overpaidAmount is typically mapped via transaction, but we provide ZERO here as a fallback placeholder.
            creditBalanceSnapshot,
            invoice.getCalculationSnapshot(),
            invoice.getStatus().name(),
            invoice.getInvoiceType().name(),
            invoice.getCancelReason(),
            invoice.getDueDate(),
            invoice.getCreatedAt(),
            detailResults
        );
    }

    private BillingContext buildBillingContext(
            RentalService service,
            ServiceUsage usage,
            Room room,
            Contract contract,
            ServicePricing pricing,
            List<ServiceTierPricing> tiers,
            MeterReading approvedReading) {
        BigDecimal basePrice = pricing != null ? pricing.getBasePrice() : BigDecimal.ZERO;
        Integer activeResidents = room.getCurrentResidentsCount() != null ? room.getCurrentResidentsCount() : 1;
        BigDecimal quantity = usage.getRegisteredQuantity() != null ? BigDecimal.valueOf(usage.getRegisteredQuantity()) : BigDecimal.ONE;
        BigDecimal oldReading = approvedReading != null ? approvedReading.getOldReading() : BigDecimal.ZERO;
        BigDecimal newReading = approvedReading != null ? approvedReading.getNewReading() : oldReading;
        BigDecimal consumption = approvedReading != null ? approvedReading.getConsumption() : null;
        if (consumption == null && approvedReading != null) {
            consumption = newReading.subtract(oldReading);
        }
        boolean meterBasedWithoutTiers = service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.METERED
                || (service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.PER_INDEX && (tiers == null || tiers.isEmpty()));

        if (service.getChargeType() == com.roomrental.modules.service.domain.model.ChargeType.PER_QUANTITY && approvedReading != null) {
            if (consumption == null) {
                consumption = newReading.subtract(oldReading);
            }
            if (consumption != null) {
                quantity = consumption.max(BigDecimal.ZERO);
            }
        } else if (meterBasedWithoutTiers && consumption != null) {
            quantity = consumption.max(BigDecimal.ZERO);
        }

        List<BillingContext.PricingTier> billingTiers = tiers == null ? List.of() : tiers.stream()
                .map(tier -> new BillingContext.PricingTier(tier.getTierStart(), tier.getTierEnd(), tier.getPricePerUnit()))
                .toList();

        return new BillingContext(
                service.getId(),
                service.getName(),
                service.getChargeType().name(),
                oldReading,
                newReading,
                quantity,
                activeResidents,
                basePrice,
                billingTiers
        );
    }

    private Map<String, Object> buildSnapshotItem(String strategyCode, boolean hasTiers, BillingContext context) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("strategyCode", strategyCode);
        item.put("hasTiers", hasTiers);
        item.put("serviceId", context.serviceId());
        item.put("serviceName", context.serviceName());
        item.put("chargeType", context.chargeType());
        item.put("oldReading", context.oldReading());
        item.put("newReading", context.newReading());
        item.put("quantity", context.quantity());
        item.put("activeResidents", context.activeResidents());
        item.put("basePrice", context.basePrice());
        item.put("pricingTiers", context.pricingTiers());
        return item;
    }

    private String buildCalculationSnapshot(
            InvoiceGenerateCommand command,
            Contract contract,
            Room room,
            List<Map<String, Object>> items,
            Long replacesInvoiceId) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        if (replacesInvoiceId != null) {
            snapshot.put("replacesInvoiceId", replacesInvoiceId);
        }
        snapshot.put("motelId", room.getMotelId());
        snapshot.put("roomId", room.getId());
        snapshot.put("contractId", contract.getId());
        snapshot.put("billingMonth", command.billingMonth());
        snapshot.put("items", items);
        try {
            return objectMapper.writeValueAsString(snapshot);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize invoice calculation snapshot", ex);
        }
    }

    @Transactional(readOnly = true)
    public InvoicePaymentInfoResult getPaymentInfo(Long id) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Invoice invoice = invoiceRepository.findByIdAndTenantId(id, tenantId)
                .orElseThrow(() -> BaseException.notFound("Invoice", id));

        Room room = roomRepository.findById(invoice.getRoomId())
                .orElseThrow(() -> BaseException.notFound("Room", invoice.getRoomId()));

        Motel motel = motelRepository.findByIdAndTenantId(room.getMotelId(), tenantId)
                .orElseThrow(() -> BaseException.notFound("Motel", room.getMotelId()));

        String bankConfigStr = motel.getBankConfig();
        if (bankConfigStr == null || bankConfigStr.isBlank()) {
            throw BaseException.badRequest("Khu trọ chưa được cấu hình tài khoản ngân hàng nhận tiền");
        }

        String bankId = "";
        String bankAccount = "";
        String accountHolder = "";
        String bankName = "";

        try {
            com.fasterxml.jackson.databind.JsonNode node = objectMapper.readTree(bankConfigStr);
            bankId = node.has("bankId") ? node.get("bankId").asText() : "";
            bankAccount = node.has("bankAccount") ? node.get("bankAccount").asText() : "";
            accountHolder = node.has("accountHolder") ? node.get("accountHolder").asText() : "";
            bankName = node.has("bankName") ? node.get("bankName").asText() : "";
        } catch (Exception e) {
            log.error("Failed to parse bank config for motel: " + motel.getId(), e);
            throw BaseException.badRequest("Cấu hình tài khoản ngân hàng của khu trọ không hợp lệ");
        }

        if (bankId.isBlank() || bankAccount.isBlank() || accountHolder.isBlank()) {
            throw BaseException.badRequest("Cấu hình tài khoản ngân hàng của khu trọ thiếu thông tin bắt buộc (bankId, bankAccount, accountHolder)");
        }

        String memo = "PT" + invoice.getId();
        // SePay requires SEVQR prefix for VietinBank (ICB) personal/household accounts to route webhooks
        if ("ICB".equalsIgnoreCase(bankId) || (bankId != null && bankId.toLowerCase().contains("vietin"))) {
            memo = "SEVQR " + memo;
        }
        BigDecimal remainingAmount = invoice.getRemainingAmount();

        String encodedHolder = "";

        try {
            encodedHolder = java.net.URLEncoder.encode(accountHolder, java.nio.charset.StandardCharsets.UTF_8.toString());
        } catch (Exception ignored) {
            encodedHolder = accountHolder;
        }

        String qrUrl = String.format("https://img.vietqr.io/image/%s-%s-compact2.png?amount=%s&addInfo=%s&accountName=%s",
                bankId, bankAccount, remainingAmount.toPlainString(), memo, encodedHolder);

        return new InvoicePaymentInfoResult(
                bankId, bankAccount, accountHolder, bankName, remainingAmount, memo, qrUrl
        );
    }
}


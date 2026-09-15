package com.roomrental.modules.report.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.audit.infrastructure.persistence.AuditLogEntity;
import com.roomrental.modules.audit.infrastructure.persistence.AuditLogJpaRepository;
import com.roomrental.modules.contract.infrastructure.persistence.ContractEntity;
import com.roomrental.modules.contract.infrastructure.persistence.ContractJpaRepository;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceEntity;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceJpaRepository;
import com.roomrental.modules.motel.infrastructure.persistence.MotelEntity;
import com.roomrental.modules.motel.infrastructure.persistence.MotelJpaRepository;
import com.roomrental.modules.report.application.dto.*;
import com.roomrental.modules.room.infrastructure.entity.RoomEntity;
import com.roomrental.modules.room.infrastructure.repository.RoomJpaRepository;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Report service for UC90, UC91, UC92, UC94.
 */
@Service
@Transactional(readOnly = true)
public class ReportService {

    private final InvoiceJpaRepository invoiceRepository;
    private final RoomJpaRepository roomRepository;
    private final ContractJpaRepository contractRepository;
    private final MotelJpaRepository motelRepository;
    private final AuditLogJpaRepository auditLogRepository;

    public ReportService(InvoiceJpaRepository invoiceRepository,
                         RoomJpaRepository roomRepository,
                         ContractJpaRepository contractRepository,
                         MotelJpaRepository motelRepository,
                         AuditLogJpaRepository auditLogRepository) {
        this.invoiceRepository = invoiceRepository;
        this.roomRepository = roomRepository;
        this.contractRepository = contractRepository;
        this.motelRepository = motelRepository;
        this.auditLogRepository = auditLogRepository;
    }

    /**
     * UC90: Revenue statistics — projected vs actual per month.
     * BR90.2: projected = SUM(total_amount)
     * BR90.3: actual = SUM(paid_amount) for PAID/PARTIAL invoices
     */
    public RevenueReportResult getRevenue(Long motelId, Integer year) {
        UUID tenantId = SecurityUtils.requireTenantId();
        validateMotelOwnership(tenantId, motelId);

        // Get all rooms in this motel (SQLRestriction handles deleted)
        List<Long> roomIds = roomRepository.findByMotelId(motelId, Pageable.unpaged())
                .stream().map(RoomEntity::getId).collect(Collectors.toList());

        // Get all contracts for these rooms
        List<Long> contractIds = contractRepository.findByTenantId(tenantId).stream()
                .filter(c -> roomIds.contains(c.getRoomId()))
                .map(ContractEntity::getId)
                .collect(Collectors.toList());

        // Get invoices for this year (not deleted)
        List<InvoiceEntity> invoices = invoiceRepository
                .findByTenantIdAndContractIdInAndIsDeletedFalse(tenantId, contractIds, Pageable.unpaged())
                .stream()
                .filter(i -> i.getBillingMonth() != null && i.getBillingMonth().getYear() == year)
                .collect(Collectors.toList());

        // Group by month
        List<RevenueReportResult.MonthlyRevenue> monthly = new ArrayList<>();
        BigDecimal totalProjected = BigDecimal.ZERO;
        BigDecimal totalActual = BigDecimal.ZERO;

        for (int m = 1; m <= 12; m++) {
            final int month = m;
            List<InvoiceEntity> monthInvoices = invoices.stream()
                    .filter(i -> i.getBillingMonth().getMonthValue() == month)
                    .collect(Collectors.toList());

            BigDecimal projected = monthInvoices.stream()
                    .map(i -> i.getTotalAmount() != null ? i.getTotalAmount() : BigDecimal.ZERO)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal actual = monthInvoices.stream()
                    .map(i -> i.getPaidAmount() != null ? i.getPaidAmount() : BigDecimal.ZERO)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            monthly.add(new RevenueReportResult.MonthlyRevenue(m, projected, actual));
            totalProjected = totalProjected.add(projected);
            totalActual = totalActual.add(actual);
        }

        BigDecimal collectionRate = totalProjected.compareTo(BigDecimal.ZERO) > 0
                ? totalActual.divide(totalProjected, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;

        return new RevenueReportResult(year, null, motelId, totalProjected, totalActual, collectionRate, monthly);
    }

    /**
     * UC91: Occupancy statistics.
     * BR91.2: OccupancyRate = (RENTED + DEPOSITED) / Total * 100
     */
    public OccupancyReportResult getOccupancy(Long motelId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        MotelEntity motel = validateMotelOwnership(tenantId, motelId);

        List<RoomEntity> rooms = roomRepository.findByMotelId(motelId, Pageable.unpaged()).getContent();

        int totalRooms = rooms.size();
        int rented = (int) rooms.stream().filter(r -> "RENTED".equals(r.getStatus())).count();
        int deposited = (int) rooms.stream().filter(r -> "DEPOSITED".equals(r.getStatus())).count();
        int available = (int) rooms.stream().filter(r -> "AVAILABLE".equals(r.getStatus())).count();
        int repairing = (int) rooms.stream().filter(r -> "REPAIRING".equals(r.getStatus())).count();

        double occupancyRate = totalRooms > 0 ? (double) (rented + deposited) / totalRooms * 100.0 : 0.0;

        List<OccupancyReportResult.RoomSummary> emptyRooms = rooms.stream()
                .filter(r -> "AVAILABLE".equals(r.getStatus()))
                .map(r -> new OccupancyReportResult.RoomSummary(
                        r.getId(), r.getRoomNumber(),
                        r.getFloor() != null ? r.getFloor().toString() : "",
                        r.getBasePrice(), r.getStatus(), null))
                .sorted(Comparator.comparingLong(OccupancyReportResult.RoomSummary::roomId))
                .collect(Collectors.toList());

        return new OccupancyReportResult(motelId, motel.getName(), totalRooms,
                rented, deposited, available, repairing, occupancyRate, emptyRooms);
    }

    /**
     * UC92: Debt report.
     * BR92.2: Debt entries from PENDING/PARTIAL invoices
     */
    public DebtReportResult getDebt(Long motelId, String sortBy) {
        UUID tenantId = SecurityUtils.requireTenantId();
        validateMotelOwnership(tenantId, motelId);

        List<Long> roomIds = roomRepository.findByMotelId(motelId, Pageable.unpaged())
                .stream().map(RoomEntity::getId).collect(Collectors.toList());
        List<Long> contractIds = contractRepository.findByTenantId(tenantId).stream()
                .filter(c -> roomIds.contains(c.getRoomId()))
                .map(ContractEntity::getId).collect(Collectors.toList());

        LocalDate today = LocalDate.now();

        List<InvoiceEntity> debtInvoices = invoiceRepository
                .findByTenantIdAndContractIdInAndIsDeletedFalse(tenantId, contractIds, Pageable.unpaged())
                .stream()
                .filter(i -> i.getStatus() != null
                        && (i.getStatus().name().equals("PENDING") || i.getStatus().name().equals("PARTIAL")))
                .collect(Collectors.toList());

        // Build room map
        Map<Long, RoomEntity> roomMap = roomIds.stream()
                .flatMap(rid -> roomRepository.findById(rid).stream())
                .collect(Collectors.toMap(RoomEntity::getId, r -> r));

        List<DebtReportResult.DebtEntry> entries = debtInvoices.stream().map(inv -> {
            BigDecimal debtAmt = (inv.getTotalAmount() != null ? inv.getTotalAmount() : BigDecimal.ZERO)
                    .subtract(inv.getPaidAmount() != null ? inv.getPaidAmount() : BigDecimal.ZERO);

            Long roomId = inv.getRoomId();
            RoomEntity room = roomId != null ? roomMap.get(roomId) : null;

            // Due date: billingMonth last day, or explicit due_date if set
            LocalDate dueDate = inv.getDueDate() != null ? inv.getDueDate()
                    : (inv.getBillingMonth() != null
                    ? inv.getBillingMonth().withDayOfMonth(inv.getBillingMonth().lengthOfMonth())
                    : today);

            int daysOverdue = (int) Math.max(0, today.toEpochDay() - dueDate.toEpochDay());
            String agingBucket = daysOverdue == 0 ? "NEW" : daysOverdue <= 30 ? "OVERDUE" : "BAD_DEBT";

            return new DebtReportResult.DebtEntry(
                    inv.getId(), roomId,
                    room != null ? room.getRoomNumber() : "",
                    null, null,
                    inv.getBillingMonth(),
                    inv.getTotalAmount(), inv.getPaidAmount(), debtAmt,
                    dueDate, daysOverdue, agingBucket);
        }).sorted("amount".equals(sortBy)
                ? Comparator.comparing(DebtReportResult.DebtEntry::debtAmount).reversed()
                : Comparator.comparingInt(DebtReportResult.DebtEntry::daysOverdue).reversed())
          .collect(Collectors.toList());

        BigDecimal totalDebt = entries.stream().map(DebtReportResult.DebtEntry::debtAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return new DebtReportResult(motelId, totalDebt, entries.size(), entries);
    }

    /**
     * UC94: Dashboard summary for current tenant.
     * Cached per-tenant in Redis (cache: "dashboardSummary", key: tenantId).
     * Cache is invalidated whenever invoices, contracts, or rooms are modified.
     */
    @Cacheable(value = "dashboardSummary", key = "#tenantId.toString()")
    public DashboardSummaryResult getDashboardSummary(UUID tenantId) {
        // tenantId được truyền từ controller (đã extract từ SecurityContext)
        // → @Cacheable key evaluation không cần SecurityContext, tránh 500 error

        // All motels
        List<MotelEntity> motels = motelRepository.findByTenantId(tenantId, Pageable.unpaged()).getContent();
        List<Long> motelIds = motels.stream().map(MotelEntity::getId).collect(Collectors.toList());

        // Room stats
        List<RoomEntity> allRooms = motelIds.stream()
                .flatMap(mid -> roomRepository.findByMotelId(mid, Pageable.unpaged()).stream())
                .collect(Collectors.toList());

        int totalRooms = allRooms.size();
        int rentedRooms = (int) allRooms.stream().filter(r -> "RENTED".equals(r.getStatus())).count();
        int availableRooms = (int) allRooms.stream().filter(r -> "AVAILABLE".equals(r.getStatus())).count();
        double occupancyRate = totalRooms > 0 ? (double) rentedRooms / totalRooms * 100.0 : 0.0;

        // Current month finance
        LocalDate now = LocalDate.now();
        List<Long> allContractIds = contractRepository.findByTenantId(tenantId).stream()
                .map(ContractEntity::getId).collect(Collectors.toList());

        List<InvoiceEntity> currentMonthInvoices = allContractIds.isEmpty()
                ? List.of()
                : invoiceRepository.findByTenantIdAndContractIdInAndIsDeletedFalse(
                        tenantId, allContractIds, Pageable.unpaged()).stream()
                .filter(i -> i.getBillingMonth() != null
                        && i.getBillingMonth().getYear() == now.getYear()
                        && i.getBillingMonth().getMonthValue() == now.getMonthValue())
                .collect(Collectors.toList());

        BigDecimal expectedRevenue = currentMonthInvoices.stream()
                .map(i -> i.getTotalAmount() != null ? i.getTotalAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal collectedRevenue = currentMonthInvoices.stream()
                .map(i -> i.getPaidAmount() != null ? i.getPaidAmount() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal pendingDebt = expectedRevenue.subtract(collectedRevenue);

        long unpaidCount = currentMonthInvoices.stream()
                .filter(i -> i.getStatus() != null
                        && (i.getStatus().name().equals("PENDING") || i.getStatus().name().equals("PARTIAL")))
                .count();

        // Contracts
        LocalDate in30Days = now.plusDays(30);
        List<ContractEntity> allContracts = contractRepository.findByTenantId(tenantId);
        long expiringCount = allContracts.stream()
                .filter(c -> "ACTIVE".equals(c.getStatus()) && c.getEndDate() != null
                        && !c.getEndDate().isBefore(now) && !c.getEndDate().isAfter(in30Days))
                .count();
        long activeCount = allContracts.stream().filter(c -> "ACTIVE".equals(c.getStatus())).count();

        // Recent activities (last 5 from audit log — no tenantId filter available, get latest)
        List<DashboardSummaryResult.RecentActivity> activities = auditLogRepository
                .findAll(PageRequest.of(0, 5, Sort.by("timestamp").descending())).stream()
                .map(a -> new DashboardSummaryResult.RecentActivity(
                        a.getAction(), a.getEntityType(),
                        (a.getAction() != null ? a.getAction() : "") + " "
                                + (a.getEntityType() != null ? a.getEntityType() : ""),
                        a.getTimestamp()))
                .collect(Collectors.toList());

        // Recent invoices (last 5 of current month)
        List<DashboardSummaryResult.RecentInvoice> recentInvoices = currentMonthInvoices.stream()
                .sorted(Comparator.comparingLong(InvoiceEntity::getId).reversed())
                .limit(5)
                .map(i -> new DashboardSummaryResult.RecentInvoice(
                        i.getId(), i.getRoomId() != null ? i.getRoomId().toString() : null,
                        null, i.getTotalAmount(),
                        i.getStatus() != null ? i.getStatus().name() : null,
                        i.getBillingMonth()))
                .collect(Collectors.toList());

        return new DashboardSummaryResult(
                totalRooms, rentedRooms, availableRooms, occupancyRate,
                expectedRevenue, collectedRevenue, pendingDebt,
                (int) expiringCount, (int) activeCount,
                (int) unpaidCount, 0,
                activities, recentInvoices);
    }

    private MotelEntity validateMotelOwnership(UUID tenantId, Long motelId) {
        return motelRepository.findByIdAndTenantId(motelId, tenantId)
                .orElseThrow(() -> BaseException.forbidden("Access denied to motel " + motelId));
    }
}

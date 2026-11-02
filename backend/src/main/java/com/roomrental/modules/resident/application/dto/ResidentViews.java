package com.roomrental.modules.resident.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Read models for the Manager's tenant screens (UC50, UC51, UC52, UC54).
 * Residency status values:
 *  LIVING      – has an ACTIVE / PENDING_LIQUIDATION contract
 *  PENDING     – latest contract is DRAFT (deposit not collected yet)
 *  NO_CONTRACT – profile created but never linked to a contract
 *  FORMER      – all contracts LIQUIDATED / CANCELED (moved out)
 */
public final class ResidentViews {

    private ResidentViews() {}

    /** UC50 list row. */
    public record Summary(
            UUID userId,
            String fullName,
            String phone,
            String email,
            String accountStatus,
            String avatarUrl,
            Long contractId,
            String contractStatus,
            String roomNumber,
            String motelName,
            String residencyStatus,
            BigDecimal debtAmount,
            int unpaidInvoiceCount
    ) {}

    /** UC52 historical tenant row (one per ended contract). */
    public record History(
            UUID userId,
            String fullName,
            String phone,
            String accountStatus,
            Long contractId,
            String contractStatus,
            String roomNumber,
            String motelName,
            LocalDate checkInDate,
            LocalDate checkOutDate,
            long stayDays,
            BigDecimal depositAmount,
            String depositStatus,
            BigDecimal settlementTotal,
            BigDecimal settlementPaid,
            String settlementStatus,
            BigDecimal remainingDebt,
            String endReason
    ) {}

    /** UC49: open contract a new resident can be linked to. */
    public record LinkableContract(
            Long id,
            String status,
            String roomNumber,
            String motelName,
            String primaryResidentName,
            LocalDate startDate,
            LocalDate endDate
    ) {}

    public record ContractItem(
            Long id,
            String status,
            String roomNumber,
            String motelName,
            LocalDate startDate,
            LocalDate endDate,
            LocalDate moveOutDate,
            BigDecimal rentPrice,
            BigDecimal depositAmount,
            String depositStatus,
            boolean primary
    ) {}

    public record InvoiceItem(
            Long id,
            Long contractId,
            String roomNumber,
            LocalDate billingMonth,
            LocalDate dueDate,
            BigDecimal totalAmount,
            BigDecimal paidAmount,
            BigDecimal remainingAmount,
            String status,
            String invoiceType
    ) {}

    public record MaintenanceItem(
            Long id,
            String roomNumber,
            String category,
            String description,
            String status,
            String priority,
            LocalDateTime createdAt,
            LocalDateTime completedAt
    ) {}

    public record ActivityItem(
            String action,
            String oldValue,
            String newValue,
            String metadata,
            OffsetDateTime timestamp
    ) {}

    /** UC51 aggregated detail. */
    public record Overview(
            ResidentResult profile,
            String residencyStatus,
            BigDecimal totalDebt,
            int unpaidInvoiceCount,
            boolean canDeactivate,
            String deactivateBlockReason,
            List<ContractItem> contracts,
            List<InvoiceItem> invoices,
            List<MaintenanceItem> maintenanceRequests,
            List<ActivityItem> activities
    ) {}
}

package com.roomrental.modules.report.application.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * UC94: Dashboard summary response.
 * Aggregated data for the main dashboard view.
 */
public record DashboardSummaryResult(
        // Room stats
        Integer totalRooms,
        Integer rentedRooms,
        Integer availableRooms,
        Double occupancyRate,

        // Finance stats for current month
        BigDecimal expectedRevenue,
        BigDecimal collectedRevenue,
        BigDecimal pendingDebt,

        // Contracts
        Integer expiringContractsCount,  // within 30 days
        Integer activeContractsCount,

        // Invoices
        Integer unpaidInvoicesCount,
        Integer pendingMeterReadingsCount,

        // Recent activities (from audit log)
        List<RecentActivity> recentActivities,

        // Recent invoices summary
        List<RecentInvoice> recentInvoices
) implements java.io.Serializable {
    public record RecentActivity(
            String action,
            String entityType,
            String description,
            java.time.OffsetDateTime createdAt
    ) implements java.io.Serializable {}

    public record RecentInvoice(
            Long invoiceId,
            String roomNumber,
            String residentName,
            java.math.BigDecimal amount,
            String status,
            java.time.LocalDate billingMonth
    ) implements java.io.Serializable {}
}

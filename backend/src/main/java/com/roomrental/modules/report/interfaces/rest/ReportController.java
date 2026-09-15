package com.roomrental.modules.report.interfaces.rest;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.modules.report.application.dto.*;
import com.roomrental.modules.report.application.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * REST controller for Reports (UC90, UC91, UC92, UC94).
 */
@RestController
@RequestMapping("/api/v1/reports")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Reports", description = "Business analytics and reporting (UC90-UC94)")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    /**
     * UC90: Revenue statistics.
     * GET /api/v1/reports/revenue?motelId=1&year=2026
     */
    @GetMapping("/revenue")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Revenue report — projected vs actual (UC90)")
    public ResponseEntity<ApiResponse<RevenueReportResult>> getRevenue(
            @RequestParam Long motelId,
            @RequestParam(defaultValue = "#{T(java.time.LocalDate).now().getYear()}") Integer year) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.getRevenue(motelId, year)));
    }

    /**
     * UC91: Occupancy statistics.
     * GET /api/v1/reports/occupancy?motelId=1
     */
    @GetMapping("/occupancy")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Occupancy report — room utilization rate (UC91)")
    public ResponseEntity<ApiResponse<OccupancyReportResult>> getOccupancy(
            @RequestParam Long motelId) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.getOccupancy(motelId)));
    }

    /**
     * UC92: Debt aging report.
     * GET /api/v1/reports/debt?motelId=1&sort=days
     */
    @GetMapping("/debt")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Debt report — outstanding balances with aging buckets (UC92)")
    public ResponseEntity<ApiResponse<DebtReportResult>> getDebt(
            @RequestParam Long motelId,
            @RequestParam(defaultValue = "days") String sort) {
        return ResponseEntity.ok(ApiResponse.ok(reportService.getDebt(motelId, sort)));
    }

    /**
     * UC94: Dashboard summary.
     * GET /api/v1/reports/dashboard-summary
     */
    @GetMapping("/dashboard-summary")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Dashboard summary — aggregated KPIs for current tenant (UC94)")
    public ResponseEntity<ApiResponse<DashboardSummaryResult>> getDashboardSummary() {
        // Lấy tenantId ở controller để @Cacheable key trong service có thể dùng #tenantId
        UUID tenantId = com.roomrental.common.util.SecurityUtils.requireTenantId();
        return ResponseEntity.ok(ApiResponse.ok(reportService.getDashboardSummary(tenantId)));
    }
}

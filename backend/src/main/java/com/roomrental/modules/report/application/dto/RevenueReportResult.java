package com.roomrental.modules.report.application.dto;

import java.math.BigDecimal;
import java.util.List;

/**
 * UC90: Revenue statistics response.
 */
public record RevenueReportResult(
        Integer year,
        Integer month,
        Long motelId,
        BigDecimal totalProjected,   // Tổng doanh thu dự kiến
        BigDecimal totalActual,      // Tổng doanh thu thực tế
        BigDecimal collectionRate,   // Tỷ lệ thu hồi (%)
        List<MonthlyRevenue> monthly
) {
    public record MonthlyRevenue(
            Integer month,
            BigDecimal projected,
            BigDecimal actual
    ) {}
}

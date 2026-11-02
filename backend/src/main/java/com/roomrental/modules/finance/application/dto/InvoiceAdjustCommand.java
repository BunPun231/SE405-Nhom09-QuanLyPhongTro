package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public record InvoiceAdjustCommand(
    Long invoiceId,
    String reason,
    Map<Long, BigDecimal> correctedReadings,
    Map<Long, BigDecimal> customAdjustments,
    List<AdjustmentLine> adjustments
) {
    public InvoiceAdjustCommand(Long invoiceId, String reason,
                                Map<Long, BigDecimal> correctedReadings,
                                Map<Long, BigDecimal> customAdjustments) {
        this(invoiceId, reason, correctedReadings, customAdjustments, List.of());
    }

    /** Một khoản phụ thu (amount > 0) hoặc giảm trừ (amount < 0). */
    public record AdjustmentLine(String description, BigDecimal amount) {}
}

package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * UC76 - Hủy và tái cấp hóa đơn.
 *
 * @param reason            lý do hủy và tái cấp (bắt buộc, BR76.3)
 * @param correctedReadings serviceId -> chỉ số mới đúng (BR76.5)
 * @param customAdjustments invoiceDetailId (của hóa đơn cũ) -> số tiền đúng của dòng đó
 * @param adjustments       các khoản phụ thu (amount > 0) / giảm trừ (amount < 0) kèm mô tả
 */
public record InvoiceAdjustRequest(
    @NotBlank String reason,
    Map<Long, BigDecimal> correctedReadings,
    Map<Long, BigDecimal> customAdjustments,
    @Valid List<AdjustmentItem> adjustments
) {
    public record AdjustmentItem(
        @NotBlank String description,
        @NotNull BigDecimal amount
    ) {}
}

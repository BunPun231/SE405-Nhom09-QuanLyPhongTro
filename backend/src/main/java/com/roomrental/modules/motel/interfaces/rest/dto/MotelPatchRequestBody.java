package com.roomrental.modules.motel.interfaces.rest.dto;

/**
 * DTO cho PATCH request - cho phép update các field riêng lẻ.
 * Tất cả field đều optional (nullable) để hỗ trợ partial updates.
 * Chỉ các field không null sẽ được update.
 * 
 * Lưu ý: Không có validation constraints ở đây vì tất cả fields đều optional.
 * Validation sẽ được thực hiện ở service layer khi cần thiết.
 */
public record MotelPatchRequestBody(
        String name,
        String address,
        Integer totalFloors,
        String description,
        Integer billingCycleDay,
        java.math.BigDecimal depositPercent,
        String bankConfig
) {
}

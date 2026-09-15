package com.roomrental.modules.contract.interfaces.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Request DTO cho tạo hợp đồng.
 */
public record ContractCreateRequestBody(
        @NotNull @Schema(description = "ID phòng", example = "1") Long roomId,
        @Schema(description = "ID cư dân chính (nếu đã có tài khoản)", example = "550e8400-e29b-41d4-a716-446655440000") String primaryResidentUserId,
        @Schema(description = "SĐT cư dân chính (để tạo mới nếu chưa có)", example = "0909123456") String primaryResidentPhone,
        @Schema(description = "Họ tên cư dân chính", example = "Nguyen Van A") String primaryResidentFullName,
        @Schema(description = "Email cư dân chính", example = "a@example.com") String primaryResidentEmail,
        @Schema(description = "CCCD cư dân chính", example = "079123456789") String primaryResidentIdCardNumber,
        @Schema(description = "Ảnh CCCD mặt trước") String primaryResidentIdCardFrontUrl,
        @Schema(description = "Ảnh CCCD mặt sau") String primaryResidentIdCardBackUrl,
        @NotNull @Schema(description = "Gia thue phong", example = "4500000") BigDecimal rentPrice,
        @NotNull @Schema(description = "Ngày bắt đầu hợp đồng", example = "2024-01-01") LocalDate startDate,
        @NotNull @Schema(description = "Ngày kết thúc hợp đồng", example = "2025-01-01") LocalDate endDate,
        @NotNull @Schema(description = "Số tiền cọc", example = "5000000") BigDecimal depositAmount,
        @Schema(description = "Trạng thái cọc", example = "UNPAID", allowableValues = {"UNPAID", "PAID", "REFUNDED", "DEDUCTED"}) String depositStatus,
        @Schema(description = "Ngay bat dau ky dong tien", example = "2026-06-01") LocalDate billingDate,
        @Schema(description = "Ngay chot ky", example = "5") Integer billingCycleDay,
        @Schema(description = "Ky dong tien (so thang)", example = "1") Integer paymentCycleMonths,
        @Schema(description = "Danh sách cư dân phụ", example = "[\"550e8400-e29b-41d4-a716-446655440111\"]") List<String> residentUserIds,
        @Schema(description = "Danh sach dich vu di kem") List<ContractServiceItemRequestBody> serviceItems
) {
}

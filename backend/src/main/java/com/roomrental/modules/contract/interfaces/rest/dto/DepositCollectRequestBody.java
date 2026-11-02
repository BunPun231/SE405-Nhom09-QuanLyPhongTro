package com.roomrental.modules.contract.interfaces.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Request DTO ghi nhan thu coc (UC69).
 */
public record DepositCollectRequestBody(
        @Schema(description = "So tien coc thuc thu", example = "5000000") BigDecimal amount,
        @Schema(description = "Ngay thu thuc te", example = "2026-06-01") LocalDate collectedDate,
        @Schema(description = "Phuong thuc", example = "CASH", allowableValues = {"CASH", "BANK_TRANSFER"}) String paymentMethod,
        @Schema(description = "Ghi chu") String note
) {
}

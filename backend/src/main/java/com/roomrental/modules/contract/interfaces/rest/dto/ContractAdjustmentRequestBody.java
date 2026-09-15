package com.roomrental.modules.contract.interfaces.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Request DTO for contract adjustments (UC66).
 */
public record ContractAdjustmentRequestBody(
        @NotBlank @Schema(description = "Loai dieu chinh", example = "PRICE_CHANGE") String type,
        @Schema(description = "Ngay hieu luc", example = "2026-06-01") LocalDate effectiveDate,
        @Schema(description = "Gia thue moi") BigDecimal newRentPrice,
        @Schema(description = "Ngay ket thuc moi", example = "2027-01-01") LocalDate newEndDate,
        @Schema(description = "Ngay du kien tra phong", example = "2026-08-15") LocalDate intendedMoveOutDate,
        @Schema(description = "Metadata JSON (manual clause)") String metadata,
        @Schema(description = "Apply new prices to current contracts (bulk appendix)") boolean applyToCurrentContracts,
        @Schema(description = "JSON array of new service prices to store in appendix, e.g. [{\"serviceId\":1,\"price\":10000}]") String newServicePrices
) {
}

package com.roomrental.modules.contract.interfaces.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

/**
 * Request DTO for contract service items.
 */
public record ContractServiceItemRequestBody(
        @NotNull @Schema(description = "ID dich vu", example = "10") Long serviceId,
        @Schema(description = "So luong (bat buoc voi dich vu theo so luong)", example = "2") Integer quantity
) {
}

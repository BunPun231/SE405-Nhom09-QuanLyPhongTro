package com.roomrental.modules.contract.application.dto;

/**
 * Command DTO for contract service items.
 */
public record ContractServiceItemCommand(
        Long serviceId,
        Integer quantity,
        java.math.BigDecimal startIndex
) {
}

package com.roomrental.modules.contract.application.dto;

/**
 * Result DTO for services attached to contract.
 */
public record ContractServiceItemResult(
        Long serviceId,
        Integer quantity
) {
}

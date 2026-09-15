package com.roomrental.modules.finance.application.dto;

public record SkippedInvoiceRoomResult(
        Long roomId,
        String roomNumber,
        String reason
) {
}
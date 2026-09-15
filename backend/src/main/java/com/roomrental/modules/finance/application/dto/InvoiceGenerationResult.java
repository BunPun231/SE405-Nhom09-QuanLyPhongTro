package com.roomrental.modules.finance.application.dto;

import java.util.List;

public record InvoiceGenerationResult(
        List<InvoiceResult> invoices,
        List<SkippedInvoiceRoomResult> skippedRooms
) {
}
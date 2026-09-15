package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;
import java.util.Map;

public record InvoiceAdjustCommand(
    Long invoiceId,
    String reason,
    Map<Long, BigDecimal> correctedReadings,
    Map<Long, BigDecimal> customAdjustments
) {}

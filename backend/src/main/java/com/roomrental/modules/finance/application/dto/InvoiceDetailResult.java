package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

public record InvoiceDetailResult(
    Long id,
    String description,
    BigDecimal quantity,
    BigDecimal unitPrice,
    BigDecimal lineTotal,
    Long serviceId
) {}

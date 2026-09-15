package com.roomrental.modules.finance.domain.port;

import java.math.BigDecimal;

public record OcrResult(
    BigDecimal extractedValue,
    double confidence,
    String rawText
) {}

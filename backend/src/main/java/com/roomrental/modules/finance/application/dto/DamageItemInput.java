package com.roomrental.modules.finance.application.dto;

import java.math.BigDecimal;

public record DamageItemInput(
    String itemName,
    BigDecimal penaltyFee,
    String imageUrl
) {}

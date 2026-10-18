package com.roomrental.modules.maintenance.application.dto;

import java.math.BigDecimal;

public record UsedDeviceItem(
        Long deviceId,
        Integer quantityUsed,
        BigDecimal unitPrice
) {}

package com.roomrental.modules.maintenance.application.dto;

import java.math.BigDecimal;
import java.util.List;

public record MaintenanceDetailResult(
        Long id,
        Long ticketId,
        Long deviceId,
        String deviceName,
        Integer quantityUsed,
        BigDecimal unitPriceSnapshot,
        List<String> afterImages,
        String note
) {}

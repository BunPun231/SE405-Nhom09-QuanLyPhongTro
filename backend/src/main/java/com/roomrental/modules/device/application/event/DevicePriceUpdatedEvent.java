package com.roomrental.modules.device.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.math.BigDecimal;
import java.util.UUID;

public record DevicePriceUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long deviceId, String deviceName, BigDecimal oldPrice, BigDecimal newPrice
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_DEVICE_PRICE"; }
    @Override public String entityType() { return "Device"; }
    @Override public String entityId() { return deviceId.toString(); }
    @Override public String oldValue() { return oldPrice != null ? oldPrice.toString() : "0"; }
    @Override public String newValue() { return newPrice != null ? newPrice.toString() : "0"; }
    @Override public String metadata() {
        return "Cập nhật giá mua thiết bị " + deviceName + " từ " + (oldPrice != null ? oldPrice : 0) + " VNĐ → " + (newPrice != null ? newPrice : 0) + " VNĐ";
    }
}

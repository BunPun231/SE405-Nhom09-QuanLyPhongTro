package com.roomrental.modules.device.application.event;

import com.roomrental.common.event.LoggableEvent;
import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.UUID;

public record DevicePriceUpdatedEvent(
        UUID tenantId, UUID actorId, String actorRole,
        Long deviceId, String deviceName, String brand,
        BigDecimal oldPrice, BigDecimal newPrice
) implements LoggableEvent {
    @Override public String action() { return "UPDATE_DEVICE_PRICE"; }
    @Override public String entityType() { return "Device"; }
    @Override public String entityId() { return deviceId.toString(); }
    @Override public String newValue() {
        return DeviceCreatedEvent.formatDeviceLabel(deviceName, brand, deviceId);
    }
    @Override public String metadata() {
        NumberFormat fmt = NumberFormat.getInstance(new Locale("vi", "VN"));
        fmt.setMaximumFractionDigits(0);
        fmt.setMinimumFractionDigits(0);
        String oldPriceStr = oldPrice != null ? fmt.format(oldPrice) + " VNĐ" : "0 VNĐ";
        String newPriceStr = newPrice != null ? fmt.format(newPrice) + " VNĐ" : "0 VNĐ";
        return "Cập nhật giá mua thiết bị " + deviceName
                + " từ " + oldPriceStr + " thành " + newPriceStr;
    }
}

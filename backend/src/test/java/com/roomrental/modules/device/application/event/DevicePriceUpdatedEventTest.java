package com.roomrental.modules.device.application.event;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("DevicePriceUpdatedEvent Unit Tests")
class DevicePriceUpdatedEventTest {

    private DevicePriceUpdatedEvent event(BigDecimal oldPrice, BigDecimal newPrice) {
        return new DevicePriceUpdatedEvent(
                UUID.randomUUID(), UUID.randomUUID(), "MANAGER",
                11L, "Máy lạnh Daikin", "FTKZ25VVMV", oldPrice, newPrice);
    }

    @Test
    @DisplayName("metadata() must contain readable old and new price with thousand separators")
    void metadataContainsFormattedPrices() {
        DevicePriceUpdatedEvent e = event(new BigDecimal("500000"), new BigDecimal("650000"));

        String metadata = e.metadata();

        assertThat(metadata).isEqualTo(
                "Cập nhật giá mua thiết bị Máy lạnh Daikin từ 500.000 VNĐ thành 650.000 VNĐ");
    }

    @Test
    @DisplayName("metadata() must fall back to 0 VNĐ when old price is null")
    void metadataHandlesNullOldPrice() {
        String metadata = event(null, new BigDecimal("1200000")).metadata();

        assertThat(metadata).contains("từ 0 VNĐ").contains("thành 1.200.000 VNĐ");
    }

    @Test
    @DisplayName("newValue formats name, brand and ID correctly")
    void newValueFormatsDeviceLabel() {
        DevicePriceUpdatedEvent e = event(new BigDecimal("100000"), new BigDecimal("200000"));

        assertThat(e.newValue()).isEqualTo("Máy lạnh Daikin (FTKZ25VVMV) • #11");
    }

    @Test
    @DisplayName("action/entityType/entityId identify the device price update")
    void identifiers() {
        DevicePriceUpdatedEvent e = event(new BigDecimal("100000"), new BigDecimal("200000"));

        assertThat(e.action()).isEqualTo("UPDATE_DEVICE_PRICE");
        assertThat(e.entityType()).isEqualTo("Device");
        assertThat(e.entityId()).isEqualTo("11");
    }
}

package com.roomrental.modules.report.application.dto;

import java.util.List;
import java.util.Map;

/**
 * UC91: Occupancy statistics response.
 */
public record OccupancyReportResult(
        Long motelId,
        String motelName,
        Integer totalRooms,
        Integer rentedRooms,
        Integer depositedRooms,
        Integer availableRooms,
        Integer repairingRooms,
        Double occupancyRate,        // (rented + deposited) / total * 100
        List<RoomSummary> emptyRooms // Sorted by longest vacancy
) {
    public record RoomSummary(
            Long roomId,
            String roomNumber,
            String floor,
            java.math.BigDecimal basePrice,
            String status,
            java.time.LocalDate lastVacantSince
    ) {}
}

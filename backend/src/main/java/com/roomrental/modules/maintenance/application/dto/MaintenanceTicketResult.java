package com.roomrental.modules.maintenance.application.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record MaintenanceTicketResult(
        Long id,
        Long roomId,
        String roomNumber,
        UUID reportedBy,
        String reporterName,
        UUID assignedTo,
        String technicianName,
        String category,
        String description,
        List<String> beforeImages,
        String status,
        String priority,
        List<MaintenanceDetailResult> details,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        OffsetDateTime completedAt
) {}

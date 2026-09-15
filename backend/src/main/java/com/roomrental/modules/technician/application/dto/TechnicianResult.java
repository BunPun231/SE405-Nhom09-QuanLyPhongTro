package com.roomrental.modules.technician.application.dto;

import java.util.List;
import java.util.UUID;

public record TechnicianResult(
        UUID userId,
        String phone,
        String email,
        String fullName,
        String status,
        List<String> expertise,
        boolean available,
        List<Integer> assignedMotelIds
) {
}

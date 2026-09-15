package com.roomrental.modules.resident.application.dto;

import java.util.UUID;

public record ResidentResult(
        UUID userId,
        String phone,
        String email,
        String fullName,
        String status,
        String idCardNumber
) {
}

package com.roomrental.modules.resident.application.dto;

import java.time.LocalDate;
import java.util.UUID;

public record ResidentResult(
        UUID userId,
        String phone,
        String email,
        String fullName,
        String status,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl,
        String avatarUrl,
        LocalDate dateOfBirth,
        String gender,
        String notes
) {
}

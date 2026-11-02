package com.roomrental.modules.resident.application.dto;

import java.time.LocalDate;
import java.util.UUID;

/**
 * UC53: Command to update resident profile info.
 * Null fields are left unchanged.
 */
public record ResidentUpdateCommand(
        UUID residentId,
        String email,
        String fullName,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl,
        String phone,
        String notes,
        LocalDate dateOfBirth,
        String gender,
        String avatarUrl
) {
}

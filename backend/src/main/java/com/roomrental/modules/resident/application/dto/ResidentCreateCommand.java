package com.roomrental.modules.resident.application.dto;

import java.time.LocalDate;

/**
 * UC49: Command to create a resident profile.
 * The 6-argument constructor is kept for callers in other modules (e.g. contract creation).
 */
public record ResidentCreateCommand(
        String phone,
        String email,
        String fullName,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl,
        LocalDate dateOfBirth,
        String gender,
        String notes,
        String avatarUrl,
        Long contractId
) {
    public ResidentCreateCommand(String phone, String email, String fullName, String idCardNumber,
                                 String idCardFrontUrl, String idCardBackUrl) {
        this(phone, email, fullName, idCardNumber, idCardFrontUrl, idCardBackUrl,
                null, null, null, null, null);
    }
}

package com.roomrental.modules.resident.interfaces.rest.dto;

import jakarta.validation.constraints.Pattern;

import java.time.LocalDate;

/**
 * UC53: Update resident profile request body.
 * All fields optional; null means "unchanged".
 */
public record ResidentUpdateRequest(
        String email,
        String fullName,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl,
        @Pattern(regexp = "^((84|0)(3|5|7|8|9)[0-9]{8})?$", message = "Invalid phone format")
        String phone,
        String notes,
        LocalDate dateOfBirth,
        @Pattern(regexp = "^(MALE|FEMALE|OTHER)?$", message = "Invalid gender")
        String gender,
        String avatarUrl
) {
}

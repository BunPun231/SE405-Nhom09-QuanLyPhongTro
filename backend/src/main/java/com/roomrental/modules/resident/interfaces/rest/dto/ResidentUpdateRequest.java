package com.roomrental.modules.resident.interfaces.rest.dto;

/**
 * UC53: Update resident profile request body.
 * Phone cannot be changed (used as login credential).
 */
public record ResidentUpdateRequest(
        String email,
        String fullName,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl
) {
}

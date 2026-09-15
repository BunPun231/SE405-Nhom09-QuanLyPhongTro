package com.roomrental.modules.resident.application.dto;

import java.util.UUID;

/**
 * UC53: Command to update resident profile info.
 */
public record ResidentUpdateCommand(
        UUID residentId,
        String email,
        String fullName,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl
) {
}

package com.roomrental.modules.resident.application.dto;

public record ResidentCreateCommand(
        String phone,
        String email,
        String fullName,
        String idCardNumber,
        String idCardFrontUrl,
        String idCardBackUrl
) {
}

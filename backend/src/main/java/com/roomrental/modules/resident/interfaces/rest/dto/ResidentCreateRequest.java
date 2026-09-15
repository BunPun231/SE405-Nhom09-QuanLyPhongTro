package com.roomrental.modules.resident.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ResidentCreateRequest(
        @NotBlank(message = "Phone is required")
        @Pattern(regexp = "^(84|0)(3|5|7|8|9)[0-9]{8}$", message = "Invalid phone format")
        String phone,

        String email,

        @NotBlank(message = "Full name is required")
        String fullName,

        @NotBlank(message = "ID card number is required")
        String idCardNumber,

        String idCardFrontUrl,
        String idCardBackUrl
) {
}

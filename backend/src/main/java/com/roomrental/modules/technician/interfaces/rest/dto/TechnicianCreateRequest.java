package com.roomrental.modules.technician.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.util.List;

public record TechnicianCreateRequest(
        @NotBlank(message = "Phone is required")
        @Pattern(regexp = "^(84|0)(3|5|7|8|9)[0-9]{8}$", message = "Invalid phone format")
        String phone,

        String email,

        @NotBlank(message = "Full name is required")
        String fullName,

        List<String> expertise,
        List<Integer> assignedMotelIds
) {
}

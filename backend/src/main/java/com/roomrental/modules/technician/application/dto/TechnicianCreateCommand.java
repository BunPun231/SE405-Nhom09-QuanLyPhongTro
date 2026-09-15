package com.roomrental.modules.technician.application.dto;

import java.util.List;

public record TechnicianCreateCommand(
        String phone,
        String email,
        String fullName,
        List<String> expertise,
        List<Integer> assignedMotelIds
) {
}

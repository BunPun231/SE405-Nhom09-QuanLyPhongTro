package com.roomrental.modules.service.interfaces.rest.dto;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record ServiceAssignRequest(
    @NotEmpty(message = "Room IDs cannot be empty")
    List<Long> roomIds
) {}

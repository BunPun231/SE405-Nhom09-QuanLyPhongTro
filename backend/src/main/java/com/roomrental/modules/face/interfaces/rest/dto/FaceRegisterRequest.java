package com.roomrental.modules.face.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public record FaceRegisterRequest(
        @NotBlank(message = "userId is required") String userId,
        @NotBlank(message = "name is required") String name,
        @NotNull(message = "embedding is required") List<Double> embedding
) {
}

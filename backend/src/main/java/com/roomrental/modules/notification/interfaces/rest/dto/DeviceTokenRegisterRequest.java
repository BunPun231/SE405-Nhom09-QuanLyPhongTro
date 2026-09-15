package com.roomrental.modules.notification.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record DeviceTokenRegisterRequest(
        @NotBlank(message = "Token cannot be blank") String token
) {}

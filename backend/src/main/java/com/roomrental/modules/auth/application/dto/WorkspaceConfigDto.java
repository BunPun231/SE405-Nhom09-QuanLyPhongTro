package com.roomrental.modules.auth.application.dto;

import java.util.Map;

public record WorkspaceConfigDto(
        Map<String, Boolean> modules
) {}

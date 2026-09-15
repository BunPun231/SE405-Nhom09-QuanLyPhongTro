package com.roomrental.modules.activity.application.dto;

import java.util.UUID;

public record ActivityLogCreateCommand(
    UUID tenantId,
    UUID actorId,
    String actorRole,
    String action,
    String entityType,
    String entityId,
    String oldValue,
    String newValue,
    String metadata
) {}

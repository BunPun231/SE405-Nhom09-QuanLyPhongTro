package com.roomrental.modules.activity.application.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record ActivityLogResult(
    Long id,
    UUID tenantId,
    UUID actorId,
    String actorRole,
    String action,
    String entityType,
    String entityId,
    String oldValue,
    String newValue,
    OffsetDateTime timestamp,
    String metadata
) {}

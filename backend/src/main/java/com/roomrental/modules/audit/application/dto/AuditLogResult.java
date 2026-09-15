package com.roomrental.modules.audit.application.dto;

import java.time.OffsetDateTime;

public record AuditLogResult(
    Long id,
    String actorId,
    String actorRole,
    String action,
    String entityType,
    String entityId,
    String oldValue,
    String newValue,
    String ipAddress,
    OffsetDateTime timestamp
) {}

package com.roomrental.modules.audit.application.dto;

import java.util.UUID;

public record AuditLogCreateCommand(
    UUID actorId,
    String actorRole,
    String action,
    String entityType,
    String entityId,
    String oldValue,
    String newValue,
    String ipAddress,
    String userAgent,
    String metadata
) {}

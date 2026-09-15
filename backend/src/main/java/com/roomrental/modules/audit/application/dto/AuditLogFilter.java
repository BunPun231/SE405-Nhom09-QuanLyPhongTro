package com.roomrental.modules.audit.application.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record AuditLogFilter(
    UUID actorId,
    String action,
    String entityType,
    OffsetDateTime fromDate,
    OffsetDateTime toDate
) {}

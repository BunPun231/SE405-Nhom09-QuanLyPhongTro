package com.roomrental.modules.activity.application.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record ActivityLogFilter(
    UUID tenantId,
    UUID actorId,
    String action,
    String entityType,
    OffsetDateTime fromDate,
    OffsetDateTime toDate
) {}

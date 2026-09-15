package com.roomrental.modules.activity.domain.model;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
public class ActivityLog {
    private Long id;
    private UUID tenantId;
    private UUID actorId;
    private String actorRole;
    private String action;
    private String entityType;
    private String entityId;
    private String oldValue;
    private String newValue;
    private OffsetDateTime timestamp;
    private String metadata;
}

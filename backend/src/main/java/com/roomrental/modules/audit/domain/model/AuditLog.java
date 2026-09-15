package com.roomrental.modules.audit.domain.model;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
public class AuditLog {
    private Long id;
    private UUID actorId;
    private String actorRole;
    private String action;
    private String entityType;
    private String entityId;
    private String oldValue;
    private String newValue;
    private String ipAddress;
    private String userAgent;
    private OffsetDateTime timestamp;
    private String metadata;
}

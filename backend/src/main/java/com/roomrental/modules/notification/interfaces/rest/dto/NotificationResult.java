package com.roomrental.modules.notification.interfaces.rest.dto;

import com.roomrental.modules.notification.domain.model.Notification;
import java.time.OffsetDateTime;
import java.util.UUID;

public record NotificationResult(
    Long id,
    UUID tenantId,
    UUID recipientUserId,
    String title,
    String content,
    String type,
    boolean isRead,
    String actionUrl,
    OffsetDateTime createdAt,
    OffsetDateTime readAt
) {
    public static NotificationResult fromDomain(Notification n) {
        if (n == null) return null;
        return new NotificationResult(
            n.getId(),
            n.getTenantId(),
            n.getRecipientUserId(),
            n.getTitle(),
            n.getContent(),
            n.getType() != null ? n.getType().name() : null,
            n.isRead(),
            n.getActionUrl(),
            n.getCreatedAt(),
            n.getReadAt()
        );
    }
}

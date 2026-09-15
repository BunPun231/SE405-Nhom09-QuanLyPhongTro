package com.roomrental.modules.notification.infrastructure.persistence;

import com.roomrental.common.entity.BaseEntity;
import com.roomrental.modules.notification.domain.model.NotificationOutbox.OutboxStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Entity(name = "NotificationOutboxEntity")
@Table(name = "notification_outbox")
@Getter
@Setter
public class NotificationOutboxEntity extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id")
    private UUID tenantId;

    @Column(name = "recipient_user_id", nullable = false)
    private UUID recipientUserId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "type", nullable = false)
    private String type;

    @Column(name = "action_url")
    private String actionUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private OutboxStatus status;

    @Column(name = "retry_count", nullable = false)
    private int retryCount = 0;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;
}

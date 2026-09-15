package com.roomrental.modules.notification.domain.model;

import java.time.OffsetDateTime;
import java.util.UUID;

public class Notification {
    private Long id;
    private UUID tenantId;
    private UUID recipientUserId;
    private String title;
    private String content;
    private NotificationType type;
    private boolean isRead;
    private String actionUrl;
    private OffsetDateTime createdAt;
    private OffsetDateTime readAt;

    public Notification() {
        this.isRead = false;
        this.createdAt = OffsetDateTime.now();
    }

    public Notification(UUID tenantId, UUID recipientUserId, String title, String content, NotificationType type, String actionUrl) {
        this.tenantId = tenantId;
        this.recipientUserId = recipientUserId;
        this.title = title;
        this.content = content;
        this.type = type;
        this.actionUrl = actionUrl;
        this.isRead = false;
        this.createdAt = OffsetDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(UUID tenantId) {
        this.tenantId = tenantId;
    }

    public UUID getRecipientUserId() {
        return recipientUserId;
    }

    public void setRecipientUserId(UUID recipientUserId) {
        this.recipientUserId = recipientUserId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public NotificationType getType() {
        return type;
    }

    public void setType(NotificationType type) {
        this.type = type;
    }

    public boolean isRead() {
        return isRead;
    }

    public void setRead(boolean read) {
        isRead = read;
    }

    public String getActionUrl() {
        return actionUrl;
    }

    public void setActionUrl(String actionUrl) {
        this.actionUrl = actionUrl;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getReadAt() {
        return readAt;
    }

    public void setReadAt(OffsetDateTime readAt) {
        this.readAt = readAt;
    }

    public void markAsRead() {
        this.isRead = true;
        this.readAt = OffsetDateTime.now();
    }
}

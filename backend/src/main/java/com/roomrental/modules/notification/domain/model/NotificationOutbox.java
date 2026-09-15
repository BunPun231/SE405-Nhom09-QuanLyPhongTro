package com.roomrental.modules.notification.domain.model;

import java.time.OffsetDateTime;
import java.util.UUID;

public class NotificationOutbox {
    private Long id;
    private UUID tenantId;
    private UUID recipientUserId;
    private String title;
    private String content;
    private String type;
    private String actionUrl;
    private OutboxStatus status;
    private int retryCount;
    private String errorMessage;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public enum OutboxStatus {
        PENDING,
        PROCESSING,
        SENT,
        FAILED
    }

    public NotificationOutbox() {
        this.status = OutboxStatus.PENDING;
        this.retryCount = 0;
        this.createdAt = OffsetDateTime.now();
    }

    public NotificationOutbox(UUID tenantId, UUID recipientUserId, String title, String content, String type, String actionUrl) {
        this.tenantId = tenantId;
        this.recipientUserId = recipientUserId;
        this.title = title;
        this.content = content;
        this.type = type;
        this.actionUrl = actionUrl;
        this.status = OutboxStatus.PENDING;
        this.retryCount = 0;
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

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getActionUrl() {
        return actionUrl;
    }

    public void setActionUrl(String actionUrl) {
        this.actionUrl = actionUrl;
    }

    public OutboxStatus getStatus() {
        return status;
    }

    public void setStatus(OutboxStatus status) {
        this.status = status;
    }

    public int getRetryCount() {
        return retryCount;
    }

    public void setRetryCount(int retryCount) {
        this.retryCount = retryCount;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public void markSent() {
        this.status = OutboxStatus.SENT;
        this.updatedAt = OffsetDateTime.now();
    }

    public void markFailed(String error) {
        this.status = OutboxStatus.FAILED;
        this.retryCount++;
        this.errorMessage = error;
        this.updatedAt = OffsetDateTime.now();
    }

    public void markProcessing() {
        this.status = OutboxStatus.PROCESSING;
        this.updatedAt = OffsetDateTime.now();
    }
}

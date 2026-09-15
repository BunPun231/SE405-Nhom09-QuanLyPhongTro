package com.roomrental.modules.notification.domain.model;

import java.time.OffsetDateTime;
import java.util.UUID;

public class DeviceToken {
    private Long id;
    private UUID userId;
    private String token;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public DeviceToken() {
        this.createdAt = OffsetDateTime.now();
    }

    public DeviceToken(UUID userId, String token) {
        this.userId = userId;
        this.token = token;
        this.createdAt = OffsetDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
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
}

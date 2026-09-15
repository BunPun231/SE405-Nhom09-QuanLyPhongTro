package com.roomrental.modules.auth.domain.model;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Domain model for User account.
 * Pure Java — fields synced with DB table "users".
 */
public class User {

    private UUID id;
    private UUID tenantId;
    private String phone;
    private String email;
    private String passwordHash;
    private String fullName;
    private UserRole role;
    private UserStatus status;
    private boolean mustChangePassword;
    private String avatarUrl;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private OffsetDateTime lastLoginAt;
    private String lockReason;
    private Integer sessionVersion = 0;
    private boolean hasCompletedOnboarding = false;

    // ── Getters & Setters ────────────────────────────────────────────

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getTenantId() { return tenantId; }
    public void setTenantId(UUID tenantId) { this.tenantId = tenantId; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public UserRole getRole() { return role; }
    public void setRole(UserRole role) { this.role = role; }

    public UserStatus getStatus() { return status; }
    public void setStatus(UserStatus status) { this.status = status; }

    public boolean isMustChangePassword() { return mustChangePassword; }
    public void setMustChangePassword(boolean mustChangePassword) { this.mustChangePassword = mustChangePassword; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public OffsetDateTime getLastLoginAt() { return lastLoginAt; }
    public void setLastLoginAt(OffsetDateTime lastLoginAt) { this.lastLoginAt = lastLoginAt; }

    public String getLockReason() { return lockReason; }
    public void setLockReason(String lockReason) { this.lockReason = lockReason; }

    public Integer getSessionVersion() { return sessionVersion; }
    public void setSessionVersion(Integer sessionVersion) { this.sessionVersion = sessionVersion; }

    public boolean isHasCompletedOnboarding() { return hasCompletedOnboarding; }
    public void setHasCompletedOnboarding(boolean hasCompletedOnboarding) { this.hasCompletedOnboarding = hasCompletedOnboarding; }
}

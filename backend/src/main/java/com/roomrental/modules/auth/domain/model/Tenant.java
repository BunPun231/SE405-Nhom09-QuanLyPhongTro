package com.roomrental.modules.auth.domain.model;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Domain model for SaaS workspace tenant.
 * Pure Java — fields synced with DB table "tenants".
 */
public class Tenant {

    private UUID id;
    private String name;
    private UUID ownerUserId;
    private TenantStatus status;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    // ── Getters & Setters ────────────────────────────────────────────

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public UUID getOwnerUserId() { return ownerUserId; }
    public void setOwnerUserId(UUID ownerUserId) { this.ownerUserId = ownerUserId; }

    public TenantStatus getStatus() { return status; }
    public void setStatus(TenantStatus status) { this.status = status; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}

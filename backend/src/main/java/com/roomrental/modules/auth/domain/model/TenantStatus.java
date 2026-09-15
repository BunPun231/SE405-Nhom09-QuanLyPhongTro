package com.roomrental.modules.auth.domain.model;

/**
 * Tenant (workspace) statuses.
 * Matches DB CHECK constraint on tenants.status.
 */
public enum TenantStatus {
    ACTIVE,
    SUSPENDED,
    TRIAL
}

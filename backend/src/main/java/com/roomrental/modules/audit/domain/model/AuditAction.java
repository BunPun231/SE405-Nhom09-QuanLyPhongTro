package com.roomrental.modules.audit.domain.model;

public enum AuditAction {
    USER_LOCK,
    USER_UNLOCK,
    USER_DELETE,
    TENANT_SUSPEND,
    TENANT_ACTIVATE,
    SYSTEM_CONFIG_UPDATE,
    SUBSCRIPTION_PLAN_CREATE,
    SUBSCRIPTION_PLAN_UPDATE,
    SUBSCRIPTION_CHANGE
}

package com.roomrental.modules.auth.domain.model;

/**
 * User account statuses.
 * Matches DB CHECK constraint on users.status.
 */
public enum UserStatus {
    ACTIVE,
    LOCKED,
    PENDING,
    INACTIVE
}

package com.roomrental.modules.auth.domain.model;

/**
 * Roles available in the system.
 * Matches DB CHECK constraint on users.role.
 */
public enum UserRole {
    ADMIN,
    MANAGER,
    TECHNICIAN,
    RESIDENT
}

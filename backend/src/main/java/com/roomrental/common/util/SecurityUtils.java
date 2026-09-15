package com.roomrental.common.util;

import com.roomrental.common.exception.BaseException;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Utility for extracting authenticated user info from SecurityContext and TenantContext.
 * Eliminates duplicated tenant/user resolution logic across service classes.
 */
public final class SecurityUtils {

    private SecurityUtils() {
    }

    /**
     * @return the current authenticated user's UUID
     * @throws BaseException if not authenticated
     */
    public static UUID getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null) {
            throw new BaseException(HttpStatus.UNAUTHORIZED, "AUTH_REQUIRED", "Authentication required");
        }
        return UUID.fromString(auth.getPrincipal().toString());
    }

    /**
     * @return the current user's role (e.g. "ADMIN", "MANAGER")
     */
    public static String getCurrentRole() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            return null;
        }
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(a -> a.startsWith("ROLE_"))
                .map(a -> a.substring(5))
                .findFirst()
                .orElse(null);
    }

    /**
     * @return the current tenant UUID from TenantContext
     * @throws BaseException if tenant context is missing
     */
    public static UUID requireTenantId() {
        String tenantId = TenantContext.getCurrentTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            throw new BaseException(HttpStatus.BAD_REQUEST, "TENANT_REQUIRED", "Missing tenant context");
        }
        return UUID.fromString(tenantId);
    }

    /**
     * @return true if the current user is authenticated
     */
    public static boolean isAuthenticated() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.isAuthenticated() && auth.getPrincipal() != null;
    }
}

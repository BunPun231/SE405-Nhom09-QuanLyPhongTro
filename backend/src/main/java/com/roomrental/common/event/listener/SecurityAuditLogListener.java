package com.roomrental.common.event.listener;

import com.roomrental.common.event.EnrichedLogEvent;
import com.roomrental.common.event.LoggableEvent;
import com.roomrental.modules.audit.application.dto.AuditLogCreateCommand;
import com.roomrental.modules.audit.application.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.Set;

/**
 * Async listener for security-sensitive audit logging.
 * Listens for ALL EnrichedLogEvents but only processes security-related actions.
 * Writes to the audit_logs table with IP address and User-Agent for forensic analysis.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SecurityAuditLogListener {

    private static final Set<String> SECURITY_ACTIONS = Set.of(
            "USER_LOGIN",
            "REGISTER_MANAGER",
            "CHANGE_PASSWORD",
            "RESET_PASSWORD",
            "LOCK_TECHNICIAN",
            "DEACTIVATE_RESIDENT",
            "RESET_TECHNICIAN_PASSWORD"
    );

    private final AuditLogService auditLogService;

    @Async("loggingExecutor")
    @EventListener
    public void handle(EnrichedLogEvent event) {
        LoggableEvent src = event.source();
        if (!SECURITY_ACTIONS.contains(src.action())) {
            return;
        }

        try {
            auditLogService.log(new AuditLogCreateCommand(
                    src.actorId(),
                    src.actorRole(),
                    src.action(),
                    src.entityType(),
                    src.entityId(),
                    src.oldValue(),
                    src.newValue(),
                    event.ipAddress(),
                    event.userAgent(),
                    src.metadata()
            ));
        } catch (Exception e) {
            log.error("Failed to write audit log for action={}: {}", src.action(), e.getMessage(), e);
        }
    }
}

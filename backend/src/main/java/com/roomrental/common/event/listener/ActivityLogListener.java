package com.roomrental.common.event.listener;

import com.roomrental.common.event.EnrichedLogEvent;
import com.roomrental.common.event.LoggableEvent;
import com.roomrental.modules.activity.application.dto.ActivityLogCreateCommand;
import com.roomrental.modules.activity.application.service.ActivityLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Async listener for tenant-scoped activity logging.
 * Only processes events that have a tenantId (i.e., belong to a tenant workspace).
 * Writes to the activity_logs table for display on the Manager's UI.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ActivityLogListener {

    private final ActivityLogService activityLogService;

    @Async("loggingExecutor")
    @EventListener(condition = "#event.source().tenantId() != null")
    public void handle(EnrichedLogEvent event) {
        try {
            LoggableEvent src = event.source();
            activityLogService.log(new ActivityLogCreateCommand(
                    src.tenantId(),
                    src.actorId(),
                    src.actorRole(),
                    src.action(),
                    src.entityType(),
                    src.entityId(),
                    src.oldValue(),
                    src.newValue(),
                    formatMetadataAsJson(src.metadata())
            ));
        } catch (Exception e) {
            log.error("Failed to write activity log for action={}: {}", event.source().action(), e.getMessage(), e);
        }
    }

    private String formatMetadataAsJson(String metadata) {
        if (metadata == null || metadata.isBlank()) {
            return null;
        }
        String trimmed = metadata.trim();
        if ((trimmed.startsWith("{") && trimmed.endsWith("}")) || 
            (trimmed.startsWith("[") && trimmed.endsWith("]"))) {
            return trimmed;
        }
        // Wrap plain text in a valid JSON object
        String escaped = trimmed.replace("\"", "\\\"");
        return "{\"value\":\"" + escaped + "\"}";
    }
}


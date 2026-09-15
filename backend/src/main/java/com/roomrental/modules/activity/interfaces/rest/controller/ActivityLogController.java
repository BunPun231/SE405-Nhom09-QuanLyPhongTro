package com.roomrental.modules.activity.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.activity.application.dto.ActivityLogFilter;
import com.roomrental.modules.activity.application.dto.ActivityLogResult;
import com.roomrental.modules.activity.application.service.ActivityLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.time.OffsetDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/activity-logs")
@Tag(name = "Activity Log", description = "Activity logging for tenant (UC14)")
@RequiredArgsConstructor
@SecurityRequirement(name = "bearerAuth")
public class ActivityLogController {

    private final ActivityLogService activityLogService;

    @GetMapping
    @PreAuthorize("hasRole('MANAGER')")
    @Operation(summary = "List activity logs for current tenant")
    public ResponseEntity<ApiResponse<Page<ActivityLogResult>>> list(
            @RequestParam(required = false) UUID actorId,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate toDate,
            Pageable pageable) {

        UUID tenantId = SecurityUtils.requireTenantId();
        OffsetDateTime from = fromDate != null ? fromDate.atStartOfDay(ZoneOffset.UTC).toOffsetDateTime() : null;
        OffsetDateTime to = null;
        if (toDate != null) {
            to = toDate.atTime(LocalTime.MAX).atZone(ZoneOffset.UTC).toOffsetDateTime();
        } else if (fromDate != null) {
            to = fromDate.atTime(LocalTime.MAX).atZone(ZoneOffset.UTC).toOffsetDateTime();
        }

        Pageable sortedPageable = org.springframework.data.domain.PageRequest.of(
                pageable.getPageNumber(),
                pageable.getPageSize(),
                org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "timestamp")
        );

        ActivityLogFilter filter = new ActivityLogFilter(tenantId, actorId, action, entityType, from, to);
        Page<ActivityLogResult> logs = activityLogService.findAll(filter, sortedPageable);
        return ResponseEntity.ok(ApiResponse.ok(logs, "Success"));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('MANAGER')")
    @Operation(summary = "Get activity log detail")
    public ResponseEntity<ApiResponse<ActivityLogResult>> getById(@PathVariable Long id) {
        ActivityLogResult result = activityLogService.findById(id);
        UUID tenantId = SecurityUtils.requireTenantId();
        if (!result.tenantId().equals(tenantId)) {
            throw new RuntimeException("Access denied");
        }
        return ResponseEntity.ok(ApiResponse.ok(result, "Success"));
    }
}

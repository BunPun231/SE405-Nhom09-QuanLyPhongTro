package com.roomrental.modules.activity.application.service;

import com.roomrental.modules.activity.application.dto.ActivityLogCreateCommand;
import com.roomrental.modules.activity.application.dto.ActivityLogFilter;
import com.roomrental.modules.activity.application.dto.ActivityLogResult;
import com.roomrental.modules.activity.domain.model.ActivityLog;
import com.roomrental.modules.activity.domain.repository.ActivityLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ActivityLogService {

    private final ActivityLogRepository activityLogRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void log(ActivityLogCreateCommand command) {
        ActivityLog log = ActivityLog.builder()
                .tenantId(command.tenantId())
                .actorId(command.actorId())
                .actorRole(command.actorRole())
                .action(command.action())
                .entityType(command.entityType())
                .entityId(command.entityId())
                .oldValue(command.oldValue())
                .newValue(command.newValue())
                .metadata(command.metadata())
                .build();
        activityLogRepository.save(log);
    }

    @Transactional(readOnly = true)
    public Page<ActivityLogResult> findAll(ActivityLogFilter filter, Pageable pageable) {
        return activityLogRepository.findAll(filter, pageable)
                .map(this::toResult);
    }

    @Transactional(readOnly = true)
    public ActivityLogResult findById(Long id) {
        return activityLogRepository.findById(id)
                .map(this::toResult)
                .orElseThrow(() -> new RuntimeException("Activity log not found"));
    }

    private ActivityLogResult toResult(ActivityLog log) {
        return new ActivityLogResult(
                log.getId(),
                log.getTenantId(),
                log.getActorId(),
                log.getActorRole(),
                log.getAction(),
                log.getEntityType(),
                log.getEntityId(),
                log.getOldValue(),
                log.getNewValue(),
                log.getTimestamp(),
                log.getMetadata()
        );
    }
}

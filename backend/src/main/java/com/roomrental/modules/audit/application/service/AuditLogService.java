package com.roomrental.modules.audit.application.service;

import com.roomrental.modules.audit.application.dto.AuditLogCreateCommand;
import com.roomrental.modules.audit.application.dto.AuditLogFilter;
import com.roomrental.modules.audit.application.dto.AuditLogResult;
import com.roomrental.modules.audit.domain.model.AuditLog;
import com.roomrental.modules.audit.domain.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void log(AuditLogCreateCommand command) {
        AuditLog log = AuditLog.builder()
                .actorId(command.actorId())
                .actorRole(command.actorRole())
                .action(command.action())
                .entityType(command.entityType())
                .entityId(command.entityId())
                .oldValue(command.oldValue())
                .newValue(command.newValue())
                .ipAddress(command.ipAddress())
                .userAgent(command.userAgent())
                .metadata(command.metadata())
                .build();
        auditLogRepository.save(log);
    }

    @Transactional(readOnly = true)
    public Page<AuditLogResult> findAll(AuditLogFilter filter, Pageable pageable) {
        return auditLogRepository.findAll(filter, pageable)
                .map(this::toResult);
    }

    @Transactional(readOnly = true)
    public AuditLogResult findById(Long id) {
        return auditLogRepository.findById(id)
                .map(this::toResult)
                .orElseThrow(() -> new RuntimeException("Audit log not found"));
    }

    private AuditLogResult toResult(AuditLog log) {
        return new AuditLogResult(
                log.getId(),
                log.getActorId() != null ? log.getActorId().toString() : null,
                log.getActorRole(),
                log.getAction(),
                log.getEntityType(),
                log.getEntityId(),
                log.getOldValue(),
                log.getNewValue(),
                log.getIpAddress(),
                log.getTimestamp()
        );
    }

    // Auto-archive logs older than 6 months (Cron job)
    @Scheduled(cron = "0 0 0 * * *") // Run daily at midnight
    @Transactional
    public void archiveOldLogs() {
        OffsetDateTime sixMonthsAgo = OffsetDateTime.now().minusMonths(6);
        auditLogRepository.deleteOlderThan(sixMonthsAgo);
    }
}

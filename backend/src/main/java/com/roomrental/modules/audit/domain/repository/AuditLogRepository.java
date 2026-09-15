package com.roomrental.modules.audit.domain.repository;

import com.roomrental.modules.audit.domain.model.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;

public interface AuditLogRepository {
    AuditLog save(AuditLog auditLog);
    Page<AuditLog> findAll(com.roomrental.modules.audit.application.dto.AuditLogFilter filter, Pageable pageable);
    Optional<AuditLog> findById(Long id);
    void deleteOlderThan(java.time.OffsetDateTime date);
}

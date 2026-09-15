package com.roomrental.modules.audit.infrastructure.mapper;

import com.roomrental.modules.audit.domain.model.AuditLog;
import com.roomrental.modules.audit.infrastructure.persistence.AuditLogEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface AuditLogMapper {
    AuditLog toDomain(AuditLogEntity entity);
    AuditLogEntity toEntity(AuditLog domain);
}

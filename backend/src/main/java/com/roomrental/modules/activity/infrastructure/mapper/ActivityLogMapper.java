package com.roomrental.modules.activity.infrastructure.mapper;

import com.roomrental.modules.activity.domain.model.ActivityLog;
import com.roomrental.modules.activity.infrastructure.persistence.ActivityLogEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface ActivityLogMapper {
    ActivityLog toDomain(ActivityLogEntity entity);
    ActivityLogEntity toEntity(ActivityLog domain);
}

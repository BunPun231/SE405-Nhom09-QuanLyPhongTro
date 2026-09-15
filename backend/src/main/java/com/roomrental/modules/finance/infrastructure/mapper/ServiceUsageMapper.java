package com.roomrental.modules.finance.infrastructure.mapper;

import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.infrastructure.persistence.ServiceUsageEntity;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface ServiceUsageMapper {
    ServiceUsage toDomain(ServiceUsageEntity entity);

    ServiceUsageEntity toEntity(ServiceUsage domain);
}
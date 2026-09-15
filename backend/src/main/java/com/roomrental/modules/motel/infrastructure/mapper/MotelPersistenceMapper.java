package com.roomrental.modules.motel.infrastructure.mapper;

import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.infrastructure.persistence.MotelEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface MotelPersistenceMapper {

    @Mapping(target = "id", source = "id")
    @Mapping(target = "tenantId", source = "tenantId")
    @Mapping(target = "name", source = "name")
    @Mapping(target = "address", source = "address")
    @Mapping(target = "totalFloors", source = "totalFloors")
    @Mapping(target = "description", source = "description")
    @Mapping(target = "billingCycleDay", source = "billingCycleDay")
    @Mapping(target = "depositPercent", source = "depositPercent")
    @Mapping(target = "bankConfig", source = "bankConfig")
    @Mapping(target = "deleted", source = "deleted")
    @Mapping(target = "createdAt", source = "createdAt")
    @Mapping(target = "updatedAt", source = "updatedAt")
    Motel toDomain(MotelEntity entity);

    MotelEntity toEntity(Motel domain);
}

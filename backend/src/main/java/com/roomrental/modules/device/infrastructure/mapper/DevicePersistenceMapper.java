package com.roomrental.modules.device.infrastructure.mapper;

import com.roomrental.modules.device.domain.model.Device;
import com.roomrental.modules.device.domain.model.DeviceStatus;
import com.roomrental.modules.device.infrastructure.entity.DeviceEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface DevicePersistenceMapper {

    @Mapping(target = "status", source = "status", qualifiedByName = "statusToStr")
    DeviceEntity toEntity(Device device);

    @Mapping(target = "status", source = "status", qualifiedByName = "strToStatus")
    Device toDomain(DeviceEntity entity);

    @Named("statusToStr")
    default String statusToStr(DeviceStatus s) { return s == null ? null : s.name(); }

    @Named("strToStatus")
    default DeviceStatus strToStatus(String s) { return s == null ? null : DeviceStatus.valueOf(s); }
}

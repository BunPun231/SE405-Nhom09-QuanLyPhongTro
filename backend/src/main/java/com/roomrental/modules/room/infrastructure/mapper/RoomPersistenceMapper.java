package com.roomrental.modules.room.infrastructure.mapper;

import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.infrastructure.entity.RoomEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface RoomPersistenceMapper {

    @Mapping(target = "status", source = "status", qualifiedByName = "statusToString")
    RoomEntity toEntity(Room room);

    @Mapping(target = "status", source = "status", qualifiedByName = "stringToStatus")
    Room toDomain(RoomEntity entity);

    @Named("statusToString")
    default String statusToString(RoomStatus status) {
        return status == null ? null : status.name();
    }

    @Named("stringToStatus")
    default RoomStatus stringToStatus(String status) {
        return status == null ? null : RoomStatus.valueOf(status);
    }
}

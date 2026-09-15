package com.roomrental.modules.finance.infrastructure.mapper;

import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.infrastructure.persistence.MeterReadingEntity;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface MeterReadingMapper {
    MeterReading toDomain(MeterReadingEntity entity);
    MeterReadingEntity toEntity(MeterReading domain);
}

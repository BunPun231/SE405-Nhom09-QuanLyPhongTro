package com.roomrental.modules.service.infrastructure.mapper;

import com.roomrental.modules.service.domain.model.ChargeType;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.infrastructure.entity.ServiceEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface ServicePersistenceMapper {

    @Mapping(target = "chargeType", source = "chargeType", qualifiedByName = "ctToString")
    ServiceEntity toEntity(RentalService service);

    @Mapping(target = "chargeType", source = "chargeType", qualifiedByName = "stringToCt")
    RentalService toDomain(ServiceEntity entity);

    @Named("ctToString")
    default String ctToString(ChargeType ct) { return ct == null ? null : ct.name(); }

    @Named("stringToCt")
    default ChargeType stringToCt(String ct) { return ct == null ? null : ChargeType.valueOf(ct); }
}

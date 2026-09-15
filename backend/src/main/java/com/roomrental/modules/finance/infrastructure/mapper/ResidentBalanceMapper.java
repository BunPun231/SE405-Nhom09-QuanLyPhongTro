package com.roomrental.modules.finance.infrastructure.mapper;

import com.roomrental.modules.finance.domain.model.ResidentBalance;
import com.roomrental.modules.finance.infrastructure.persistence.ResidentBalanceEntity;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface ResidentBalanceMapper {
    ResidentBalance toDomain(ResidentBalanceEntity entity);
    ResidentBalanceEntity toEntity(ResidentBalance domain);
}

package com.roomrental.modules.contract.infrastructure.mapper;

import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.infrastructure.persistence.ContractEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

/**
 * MapStruct Mapper cho Contract ↔ ContractEntity.
 */
@Mapper(componentModel = "spring", unmappedSourcePolicy = ReportingPolicy.IGNORE)
public interface ContractMapper {
    Contract toDomain(ContractEntity entity);

    @Mapping(target = "cancelReason", source = "cancelReason")
    ContractEntity toEntity(Contract domain);
}

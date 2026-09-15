package com.roomrental.modules.finance.infrastructure.mapper;

import com.roomrental.modules.finance.domain.model.Transaction;
import com.roomrental.modules.finance.infrastructure.persistence.TransactionEntity;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface TransactionMapper {
    Transaction toDomain(TransactionEntity entity);
    TransactionEntity toEntity(Transaction domain);
}

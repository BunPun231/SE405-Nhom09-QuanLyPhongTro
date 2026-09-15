package com.roomrental.modules.finance.infrastructure.mapper;

import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface InvoiceMapper {
    @Mapping(target = "details", ignore = true)
    Invoice toDomain(InvoiceEntity entity);
    
    InvoiceEntity toEntity(Invoice domain);
}

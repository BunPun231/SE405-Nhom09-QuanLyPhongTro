package com.roomrental.modules.finance.infrastructure.mapper;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceDetailEntity;
import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;

import java.util.List;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface InvoiceDetailMapper {
    InvoiceDetail toDomain(InvoiceDetailEntity entity);
    InvoiceDetailEntity toEntity(InvoiceDetail domain);
    
    List<InvoiceDetail> toDomainList(List<InvoiceDetailEntity> entities);
    List<InvoiceDetailEntity> toEntityList(List<InvoiceDetail> domains);
}

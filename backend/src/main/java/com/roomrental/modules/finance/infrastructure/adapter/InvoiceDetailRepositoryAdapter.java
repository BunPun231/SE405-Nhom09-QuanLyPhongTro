package com.roomrental.modules.finance.infrastructure.adapter;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import com.roomrental.modules.finance.domain.repository.InvoiceDetailRepository;
import com.roomrental.modules.finance.infrastructure.mapper.InvoiceDetailMapper;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceDetailJpaRepository;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class InvoiceDetailRepositoryAdapter implements InvoiceDetailRepository {

    private final InvoiceDetailJpaRepository jpaRepository;
    private final InvoiceDetailMapper mapper;

    public InvoiceDetailRepositoryAdapter(InvoiceDetailJpaRepository jpaRepository, InvoiceDetailMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    public InvoiceDetail save(InvoiceDetail detail) {
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(detail)));
    }

    @Override
    public List<InvoiceDetail> saveAll(List<InvoiceDetail> details) {
        return mapper.toDomainList(jpaRepository.saveAll(mapper.toEntityList(details)));
    }

    @Override
    public List<InvoiceDetail> findByInvoiceId(Long invoiceId) {
        return mapper.toDomainList(jpaRepository.findByInvoiceId(invoiceId));
    }

    @Override
    public void deleteByInvoiceId(Long invoiceId) {
        jpaRepository.deleteByInvoiceId(invoiceId);
    }
}

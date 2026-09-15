package com.roomrental.modules.finance.infrastructure.adapter;

import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import com.roomrental.modules.finance.infrastructure.mapper.InvoiceMapper;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceEntity;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class InvoiceRepositoryAdapter implements InvoiceRepository {

    private final InvoiceJpaRepository jpaRepository;
    private final InvoiceMapper mapper;

    public InvoiceRepositoryAdapter(InvoiceJpaRepository jpaRepository, InvoiceMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    public Invoice save(Invoice invoice) {
        InvoiceEntity entity = mapper.toEntity(invoice);
        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public Optional<Invoice> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Invoice> findByIdAndTenantId(Long id, UUID tenantId) {
        return jpaRepository.findByIdAndTenantId(id, tenantId).map(mapper::toDomain);
    }

    @Override
    public Page<Invoice> findByTenantId(UUID tenantId, Pageable pageable) {
        return jpaRepository.findByTenantIdAndIsDeletedFalse(tenantId, pageable).map(mapper::toDomain);
    }

    @Override
    public Page<Invoice> findByTenantIdAndStatus(UUID tenantId, String status, Pageable pageable) {
        return jpaRepository.findByTenantIdAndStatusAndIsDeletedFalse(tenantId, Invoice.InvoiceStatus.valueOf(status), pageable).map(mapper::toDomain);
    }

    @Override
    public Page<Invoice> findByContractId(Long contractId, Pageable pageable) {
        return jpaRepository.findByContractIdAndIsDeletedFalse(contractId, pageable).map(mapper::toDomain);
    }

    @Override
    public Page<Invoice> findByTenantIdAndContractIdIn(UUID tenantId, List<Long> contractIds, Pageable pageable) {
        return jpaRepository.findByTenantIdAndContractIdInAndIsDeletedFalse(tenantId, contractIds, pageable).map(mapper::toDomain);
    }

    @Override
    public Page<Invoice> findByTenantIdAndContractIdInAndStatus(UUID tenantId, List<Long> contractIds, String status, Pageable pageable) {
        return jpaRepository.findByTenantIdAndContractIdInAndStatusAndIsDeletedFalse(tenantId, contractIds, Invoice.InvoiceStatus.valueOf(status), pageable).map(mapper::toDomain);
    }

    @Override
    public boolean existsByContractIdAndBillingMonth(Long contractId, LocalDate billingMonth) {
        return jpaRepository.existsByContractIdAndBillingMonthAndIsDeletedFalse(contractId, billingMonth);
    }

    @Override
    public List<Invoice> findUnpaidByContractId(Long contractId) {
        return jpaRepository.findUnpaidByContractId(contractId).stream()
                .map(mapper::toDomain).collect(Collectors.toList());
    }

    @Override
    public Optional<UUID> findTenantIdByInvoiceIdNative(Long invoiceId) {
        return jpaRepository.findTenantIdByInvoiceIdNative(invoiceId).map(UUID::fromString);
    }

    @Override
    public void softDelete(Long id) {
        jpaRepository.softDelete(id);
    }
}

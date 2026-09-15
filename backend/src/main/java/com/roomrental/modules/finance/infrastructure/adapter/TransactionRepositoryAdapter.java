package com.roomrental.modules.finance.infrastructure.adapter;

import com.roomrental.modules.finance.domain.model.Transaction;
import com.roomrental.modules.finance.domain.repository.TransactionRepository;
import com.roomrental.modules.finance.infrastructure.mapper.TransactionMapper;
import com.roomrental.modules.finance.infrastructure.persistence.TransactionEntity;
import com.roomrental.modules.finance.infrastructure.persistence.TransactionJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class TransactionRepositoryAdapter implements TransactionRepository {

    private final TransactionJpaRepository jpaRepository;
    private final TransactionMapper mapper;

    public TransactionRepositoryAdapter(TransactionJpaRepository jpaRepository, TransactionMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    public Transaction save(Transaction transaction) {
        TransactionEntity entity = mapper.toEntity(transaction);
        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public Optional<Transaction> findByTransactionRef(String transactionRef) {
        return jpaRepository.findByTransactionRef(transactionRef).map(mapper::toDomain);
    }

    @Override
    public Optional<Transaction> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<Transaction> findByInvoiceId(Long invoiceId) {
        return jpaRepository.findByInvoiceId(invoiceId).stream()
                .map(mapper::toDomain).collect(Collectors.toList());
    }

    @Override
    public Page<Transaction> findByTenantId(UUID tenantId, Pageable pageable) {
        return jpaRepository.findByTenantId(tenantId, pageable).map(mapper::toDomain);
    }

    @Override
    public boolean existsByInvoiceId(Long invoiceId) {
        return jpaRepository.existsByInvoiceId(invoiceId);
    }
}

package com.roomrental.modules.finance.domain.repository;

import com.roomrental.modules.finance.domain.model.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository {
    Transaction save(Transaction transaction);
    Optional<Transaction> findById(Long id);
    Optional<Transaction> findByTransactionRef(String transactionRef);
    List<Transaction> findByInvoiceId(Long invoiceId);
    Page<Transaction> findByTenantId(UUID tenantId, Pageable pageable);
    boolean existsByInvoiceId(Long invoiceId);
}

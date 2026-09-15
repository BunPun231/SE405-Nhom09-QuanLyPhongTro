package com.roomrental.modules.finance.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransactionJpaRepository extends JpaRepository<TransactionEntity, Long> {
    Optional<TransactionEntity> findByTransactionRef(String transactionRef);
    List<TransactionEntity> findByInvoiceId(Long invoiceId);
    Page<TransactionEntity> findByTenantId(UUID tenantId, Pageable pageable);
    boolean existsByInvoiceId(Long invoiceId);
}

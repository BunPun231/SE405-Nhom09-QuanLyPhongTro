package com.roomrental.modules.finance.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InvoiceDetailJpaRepository extends JpaRepository<InvoiceDetailEntity, Long> {
    List<InvoiceDetailEntity> findByInvoiceId(Long invoiceId);
    void deleteByInvoiceId(Long invoiceId);
}

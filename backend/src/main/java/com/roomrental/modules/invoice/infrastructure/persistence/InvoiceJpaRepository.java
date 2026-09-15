package com.roomrental.modules.invoice.infrastructure.persistence;

import java.time.LocalDate;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InvoiceJpaRepository extends JpaRepository<InvoiceEntity, Long> {
    boolean existsByContractIdAndStatusAndBillingMonthLessThanEqual(Long contractId, String status, LocalDate billingMonth);
}

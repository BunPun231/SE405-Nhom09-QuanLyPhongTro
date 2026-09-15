package com.roomrental.modules.invoice.infrastructure.adapter;

import com.roomrental.modules.invoice.domain.repository.InvoiceReadRepository;
import com.roomrental.modules.finance.infrastructure.persistence.InvoiceJpaRepository;
import com.roomrental.modules.finance.domain.model.Invoice.InvoiceStatus;
import java.time.LocalDate;
import org.springframework.stereotype.Component;

@Component
public class InvoiceReadRepositoryAdapter implements InvoiceReadRepository {
    private final InvoiceJpaRepository jpaRepository;

    public InvoiceReadRepositoryAdapter(InvoiceJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public boolean existsPaidInvoiceCovering(Long contractId, LocalDate effectiveDate) {
        return jpaRepository.existsByContractIdAndStatusAndBillingMonthLessThanEqual(
                contractId,
                InvoiceStatus.PAID,
                effectiveDate
        );
    }
}

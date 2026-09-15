package com.roomrental.modules.invoice.domain.repository;

import java.time.LocalDate;

/**
 * Read-only invoice lookup for contract adjustments.
 */
public interface InvoiceReadRepository {
    boolean existsPaidInvoiceCovering(Long contractId, LocalDate effectiveDate);
}

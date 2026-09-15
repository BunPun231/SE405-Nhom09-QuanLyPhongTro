package com.roomrental.modules.finance.domain.repository;

import com.roomrental.modules.finance.domain.model.Invoice;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvoiceRepository {
    Invoice save(Invoice invoice);
    Optional<Invoice> findById(Long id);
    Optional<Invoice> findByIdAndTenantId(Long id, UUID tenantId);
    Page<Invoice> findByTenantId(UUID tenantId, Pageable pageable);
    Page<Invoice> findByTenantIdAndStatus(UUID tenantId, String status, Pageable pageable);
    Page<Invoice> findByContractId(Long contractId, Pageable pageable);
    Page<Invoice> findByTenantIdAndContractIdIn(UUID tenantId, List<Long> contractIds, Pageable pageable);
    Page<Invoice> findByTenantIdAndContractIdInAndStatus(UUID tenantId, List<Long> contractIds, String status, Pageable pageable);
    boolean existsByContractIdAndBillingMonth(Long contractId, LocalDate billingMonth);
    List<Invoice> findUnpaidByContractId(Long contractId);
    Optional<UUID> findTenantIdByInvoiceIdNative(Long invoiceId);
    void softDelete(Long id);
}

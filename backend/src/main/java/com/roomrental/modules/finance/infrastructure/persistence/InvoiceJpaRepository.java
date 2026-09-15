package com.roomrental.modules.finance.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository("financeInvoiceJpaRepository")
public interface InvoiceJpaRepository extends JpaRepository<InvoiceEntity, Long> {
    Optional<InvoiceEntity> findByIdAndTenantId(Long id, UUID tenantId);
    Page<InvoiceEntity> findByTenantIdAndIsDeletedFalse(UUID tenantId, Pageable pageable);
    long countByTenantIdAndIsDeletedFalse(UUID tenantId);
    
    @Query("SELECT i FROM FinanceInvoiceEntity i WHERE i.tenantId = :tenantId AND i.status = :status AND i.isDeleted = false")
    Page<InvoiceEntity> findByTenantIdAndStatusAndIsDeletedFalse(@Param("tenantId") UUID tenantId, @Param("status") com.roomrental.modules.finance.domain.model.Invoice.InvoiceStatus status, Pageable pageable);
    
    Page<InvoiceEntity> findByContractIdAndIsDeletedFalse(Long contractId, Pageable pageable);
    
    Page<InvoiceEntity> findByTenantIdAndContractIdInAndIsDeletedFalse(UUID tenantId, List<Long> contractIds, Pageable pageable);
    
    @Query("SELECT i FROM FinanceInvoiceEntity i WHERE i.tenantId = :tenantId AND i.contractId IN :contractIds AND i.status = :status AND i.isDeleted = false")
    Page<InvoiceEntity> findByTenantIdAndContractIdInAndStatusAndIsDeletedFalse(@Param("tenantId") UUID tenantId, @Param("contractIds") List<Long> contractIds, @Param("status") com.roomrental.modules.finance.domain.model.Invoice.InvoiceStatus status, Pageable pageable);
    
    boolean existsByContractIdAndBillingMonthAndIsDeletedFalse(Long contractId, LocalDate billingMonth);
    boolean existsByContractIdAndStatusAndBillingMonthLessThanEqual(Long contractId, com.roomrental.modules.finance.domain.model.Invoice.InvoiceStatus status, LocalDate billingMonth);

    
    @Query("SELECT i FROM FinanceInvoiceEntity i WHERE i.contractId = :contractId AND i.status IN ('PENDING', 'PARTIAL') AND i.isDeleted = false")
    List<InvoiceEntity> findUnpaidByContractId(@Param("contractId") Long contractId);

    @Query(value = "SELECT CAST(tenant_id AS VARCHAR) FROM invoices WHERE id = :invoiceId AND is_deleted = false", nativeQuery = true)
    Optional<String> findTenantIdByInvoiceIdNative(@Param("invoiceId") Long invoiceId);

    @Modifying
    @Query("UPDATE FinanceInvoiceEntity i SET i.isDeleted = true WHERE i.id = :id")
    void softDelete(@Param("id") Long id);
}

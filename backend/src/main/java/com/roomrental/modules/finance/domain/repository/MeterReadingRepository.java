package com.roomrental.modules.finance.domain.repository;

import com.roomrental.modules.finance.domain.model.MeterReading;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MeterReadingRepository {
    MeterReading save(MeterReading reading);
    List<MeterReading> saveAll(Iterable<MeterReading> readings);
    Optional<MeterReading> findById(Long id);
    Optional<MeterReading> findByIdAndTenantId(Long id, UUID tenantId);
    List<MeterReading> findByRoomIdAndTenantId(Long roomId, UUID tenantId);
    List<MeterReading> findByRoomIdAndBillingMonth(Long roomId, LocalDate billingMonth);
    Page<MeterReading> findByTenantId(UUID tenantId, Pageable pageable);
    Page<MeterReading> findByTenantIdAndStatus(UUID tenantId, String status, Pageable pageable);
    Page<MeterReading> findByTenantIdAndRoomId(UUID tenantId, Long roomId, Pageable pageable);
    Page<MeterReading> findByTenantIdAndRoomIdAndStatus(UUID tenantId, Long roomId, String status, Pageable pageable);
    Page<MeterReading> findPendingByTenantId(UUID tenantId, Pageable pageable);
    List<MeterReading> findApprovedByRoomIdAndBillingMonth(Long roomId, LocalDate billingMonth);
    Optional<MeterReading> findLatestApprovedByServiceUsageId(Long serviceUsageId);
    boolean existsByServiceUsageIdAndBillingMonthAndStatus(Long serviceUsageId, LocalDate billingMonth, String status);
}

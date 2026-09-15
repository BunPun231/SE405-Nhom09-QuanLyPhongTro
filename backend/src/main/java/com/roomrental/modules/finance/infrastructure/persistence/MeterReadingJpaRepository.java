package com.roomrental.modules.finance.infrastructure.persistence;

import com.roomrental.modules.finance.domain.model.MeterReading.MeterReadingStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MeterReadingJpaRepository extends JpaRepository<MeterReadingEntity, Long> {
    Optional<MeterReadingEntity> findByIdAndTenantId(Long id, UUID tenantId);
    List<MeterReadingEntity> findByRoomIdAndTenantId(Long roomId, UUID tenantId);
    long countByTenantId(UUID tenantId);
    List<MeterReadingEntity> findByRoomIdAndBillingMonth(Long roomId, LocalDate billingMonth);
    Page<MeterReadingEntity> findByTenantId(UUID tenantId, Pageable pageable);
    Page<MeterReadingEntity> findByTenantIdAndStatus(UUID tenantId, MeterReadingStatus status, Pageable pageable);
    Page<MeterReadingEntity> findByTenantIdAndRoomId(UUID tenantId, Long roomId, Pageable pageable);
    Page<MeterReadingEntity> findByTenantIdAndRoomIdAndStatus(UUID tenantId, Long roomId, MeterReadingStatus status, Pageable pageable);
    List<MeterReadingEntity> findByRoomIdAndBillingMonthAndStatus(Long roomId, LocalDate billingMonth, MeterReadingStatus status);
    Optional<MeterReadingEntity> findFirstByServiceUsageIdAndStatusOrderByBillingMonthDescCreatedAtDesc(Long serviceUsageId, MeterReadingStatus status);
    boolean existsByServiceUsageIdAndBillingMonthAndStatus(Long serviceUsageId, LocalDate billingMonth, MeterReadingStatus status);
}

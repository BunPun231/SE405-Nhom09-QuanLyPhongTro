package com.roomrental.modules.contract.domain.repository;

import com.roomrental.modules.contract.domain.model.Contract;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Port interface cho Contract Repository.
 * Định nghĩa các phương thức mà infrastructure layer phải cung cấp.
 */
public interface ContractRepository {
    Contract save(Contract contract);

    Optional<Contract> findById(Long id);

    Optional<Contract> findByIdAndTenantId(Long id, UUID tenantId);

    List<Contract> findByTenantId(UUID tenantId);

    Page<Contract> findByTenantIdAndMotelId(UUID tenantId, Long motelId, Pageable pageable);

    Page<Contract> findByTenantIdAndMotelIdAndStatus(UUID tenantId, Long motelId, String status, Pageable pageable);

    Page<Contract> findExpiringByTenantIdAndMotelId(UUID tenantId, Long motelId, LocalDate fromDate, LocalDate toDate, Pageable pageable);

    List<Contract> findByRoomId(Long roomId);

    List<Contract> findActiveByTenantId(UUID tenantId);

    boolean existsActiveByRoomId(UUID tenantId, Long roomId);

    List<Contract> findByResidentUserId(UUID tenantId, UUID residentUserId);

    void delete(Long id);

    boolean existsById(Long id);

    long countByTenantId(UUID tenantId);

    List<Contract> findAllActiveContractsNative();
}

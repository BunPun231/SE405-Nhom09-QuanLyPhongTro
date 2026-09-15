package com.roomrental.modules.contract.infrastructure.persistence;

import java.time.LocalDate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Spring Data JPA Repository cho ContractEntity.
 */
@Repository
public interface ContractJpaRepository extends JpaRepository<ContractEntity, Long> {
    Optional<ContractEntity> findByIdAndTenantId(Long id, UUID tenantId);

    List<ContractEntity> findByTenantId(UUID tenantId);

        @Query("SELECT c FROM ContractEntity c WHERE c.tenantId = :tenantId AND " +
           "c.roomId IN (SELECT r.id FROM RoomEntity r WHERE r.motelId = :motelId)")
        Page<ContractEntity> findByTenantIdAndMotelId(
            @Param("tenantId") UUID tenantId,
            @Param("motelId") Long motelId,
            Pageable pageable
        );

        @Query("SELECT c FROM ContractEntity c WHERE c.tenantId = :tenantId AND c.status = :status AND " +
           "c.roomId IN (SELECT r.id FROM RoomEntity r WHERE r.motelId = :motelId)")
        Page<ContractEntity> findByTenantIdAndMotelIdAndStatus(
            @Param("tenantId") UUID tenantId,
            @Param("motelId") Long motelId,
            @Param("status") String status,
            Pageable pageable
        );

        @Query("SELECT c FROM ContractEntity c WHERE c.tenantId = :tenantId AND " +
           "c.endDate BETWEEN :fromDate AND :toDate AND " +
           "c.roomId IN (SELECT r.id FROM RoomEntity r WHERE r.motelId = :motelId)")
        Page<ContractEntity> findExpiringByTenantIdAndMotelId(
            @Param("tenantId") UUID tenantId,
            @Param("motelId") Long motelId,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate,
            Pageable pageable
        );

    List<ContractEntity> findByRoomId(Long roomId);

    @Query("SELECT c FROM ContractEntity c WHERE c.tenantId = :tenantId AND c.status = 'ACTIVE'")
    List<ContractEntity> findActiveByTenantId(@Param("tenantId") UUID tenantId);

    @Query("SELECT COUNT(c) FROM ContractEntity c WHERE c.tenantId = :tenantId AND c.status = 'ACTIVE'")
    long countActiveByTenantId(@Param("tenantId") UUID tenantId);

    @Query("SELECT COUNT(c) > 0 FROM ContractEntity c WHERE c.tenantId = :tenantId AND c.roomId = :roomId AND c.status = 'ACTIVE'")
    boolean existsActiveByRoomId(@Param("tenantId") UUID tenantId, @Param("roomId") Long roomId);

        @Query("SELECT c FROM ContractEntity c WHERE c.tenantId = :tenantId AND (" +
            "c.primaryResidentUserId = :residentUserId OR " +
            "EXISTS (SELECT 1 FROM ContractResidentEntity cr WHERE cr.contractId = c.id AND cr.residentUserId = :residentUserId))")
        List<ContractEntity> findByResidentUserId(
             @Param("tenantId") UUID tenantId,
             @Param("residentUserId") UUID residentUserId
        );

    @Query(value = "SELECT * FROM contracts WHERE status = 'ACTIVE'", nativeQuery = true)
    List<ContractEntity> findAllActiveContractsNative();
}

package com.roomrental.modules.motel.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface MotelJpaRepository extends JpaRepository<MotelEntity, Long> {

    Optional<MotelEntity> findByIdAndTenantId(Long id, UUID tenantId);

    Page<MotelEntity> findByTenantId(UUID tenantId, Pageable pageable);

    long countByTenantIdAndDeletedFalse(UUID tenantId);

    java.util.List<MotelEntity> findByTenantIdAndDeletedFalse(UUID tenantId);
}

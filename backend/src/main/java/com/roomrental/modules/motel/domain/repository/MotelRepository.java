package com.roomrental.modules.motel.domain.repository;

import com.roomrental.modules.motel.domain.model.Motel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;
import java.util.UUID;

/**
 * Port for Motel persistence — implemented by infrastructure adapter.
 */
public interface MotelRepository {

    Motel save(Motel motel);

    Optional<Motel> findByIdAndTenantId(Long id, UUID tenantId);

    Page<Motel> findByTenantId(UUID tenantId, Pageable pageable);
}

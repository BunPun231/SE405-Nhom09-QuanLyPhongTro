package com.roomrental.modules.auth.domain.repository;

import com.roomrental.modules.auth.domain.model.Tenant;

import java.util.Optional;
import java.util.UUID;

/**
 * Port for Tenant persistence — implemented by infrastructure adapter.
 */
public interface TenantRepository {

    Tenant save(Tenant tenant);

    Optional<Tenant> findById(UUID id);

    boolean existsByName(String name);
}

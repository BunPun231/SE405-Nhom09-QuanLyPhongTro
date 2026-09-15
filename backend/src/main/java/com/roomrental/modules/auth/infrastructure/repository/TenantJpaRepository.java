package com.roomrental.modules.auth.infrastructure.repository;

import com.roomrental.modules.auth.infrastructure.entity.TenantEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TenantJpaRepository extends JpaRepository<TenantEntity, UUID> {

    boolean existsByName(String name);
}

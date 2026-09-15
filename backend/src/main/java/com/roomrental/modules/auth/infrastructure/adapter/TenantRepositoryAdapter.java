package com.roomrental.modules.auth.infrastructure.adapter;

import com.roomrental.modules.auth.domain.model.Tenant;
import com.roomrental.modules.auth.domain.repository.TenantRepository;
import com.roomrental.modules.auth.infrastructure.mapper.AuthPersistenceMapper;
import com.roomrental.modules.auth.infrastructure.repository.TenantJpaRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class TenantRepositoryAdapter implements TenantRepository {

    private final TenantJpaRepository jpa;
    private final AuthPersistenceMapper mapper;

    public TenantRepositoryAdapter(TenantJpaRepository jpa, AuthPersistenceMapper mapper) {
        this.jpa = jpa;
        this.mapper = mapper;
    }

    @Override
    public Tenant save(Tenant tenant) {
        return mapper.toDomain(jpa.save(mapper.toEntity(tenant)));
    }

    @Override
    public Optional<Tenant> findById(UUID id) {
        return jpa.findById(id).map(mapper::toDomain);
    }

    @Override
    public boolean existsByName(String name) {
        return jpa.existsByName(name);
    }
}

package com.roomrental.modules.motel.infrastructure.adapter;

import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.motel.infrastructure.mapper.MotelPersistenceMapper;
import com.roomrental.modules.motel.infrastructure.persistence.MotelEntity;
import com.roomrental.modules.motel.infrastructure.persistence.MotelJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class MotelRepositoryAdapter implements MotelRepository {

    private final MotelJpaRepository jpa;
    private final MotelPersistenceMapper mapper;

    public MotelRepositoryAdapter(MotelJpaRepository jpa, MotelPersistenceMapper mapper) {
        this.jpa = jpa;
        this.mapper = mapper;
    }

    @Override
    public Motel save(Motel motel) {
        MotelEntity entity = mapper.toEntity(motel);
        return mapper.toDomain(jpa.save(entity));
    }

    @Override
    public Optional<Motel> findByIdAndTenantId(Long id, UUID tenantId) {
        return jpa.findByIdAndTenantId(id, tenantId).map(mapper::toDomain);
    }

    @Override
    public Page<Motel> findByTenantId(UUID tenantId, Pageable pageable) {
        return jpa.findByTenantId(tenantId, pageable).map(mapper::toDomain);
    }
}

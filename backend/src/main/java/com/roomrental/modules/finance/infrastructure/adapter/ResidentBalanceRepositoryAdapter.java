package com.roomrental.modules.finance.infrastructure.adapter;

import com.roomrental.modules.finance.domain.model.ResidentBalance;
import com.roomrental.modules.finance.domain.repository.ResidentBalanceRepository;
import com.roomrental.modules.finance.infrastructure.mapper.ResidentBalanceMapper;
import com.roomrental.modules.finance.infrastructure.persistence.ResidentBalanceEntity;
import com.roomrental.modules.finance.infrastructure.persistence.ResidentBalanceJpaRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class ResidentBalanceRepositoryAdapter implements ResidentBalanceRepository {

    private final ResidentBalanceJpaRepository repository;
    private final ResidentBalanceMapper mapper;

    public ResidentBalanceRepositoryAdapter(ResidentBalanceJpaRepository repository, ResidentBalanceMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public Optional<ResidentBalance> findById(UUID residentUserId) {
        return repository.findById(residentUserId).map(mapper::toDomain);
    }

    @Override
    public ResidentBalance save(ResidentBalance balance) {
        ResidentBalanceEntity entity = mapper.toEntity(balance);
        ResidentBalanceEntity saved = repository.save(entity);
        return mapper.toDomain(saved);
    }
}

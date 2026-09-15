package com.roomrental.modules.contract.infrastructure.adapter;

import com.roomrental.modules.contract.domain.model.ContractAppendix;
import com.roomrental.modules.contract.domain.repository.ContractAppendixRepository;
import com.roomrental.modules.contract.infrastructure.persistence.ContractAppendixEntity;
import com.roomrental.modules.contract.infrastructure.persistence.ContractAppendixJpaRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

@Component
public class ContractAppendixRepositoryAdapter implements ContractAppendixRepository {
    private final ContractAppendixJpaRepository jpaRepository;

    public ContractAppendixRepositoryAdapter(ContractAppendixJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public ContractAppendix save(ContractAppendix appendix) {
        ContractAppendixEntity saved = jpaRepository.save(toEntity(appendix));
        return toDomain(saved);
    }

    @Override
    public List<ContractAppendix> findByContractId(Long contractId) {
        return jpaRepository.findByContractId(contractId).stream().map(this::toDomain).toList();
    }

    @Override
    public Page<ContractAppendix> findByContractId(Long contractId, Pageable pageable) {
        return jpaRepository.findByContractId(contractId, pageable).map(this::toDomain);
    }

    @Override
    public long countByContractId(Long contractId) {
        return jpaRepository.countByContractId(contractId);
    }

    @Override
    public Optional<ContractAppendix> findById(Long id) {
        return jpaRepository.findById(id).map(this::toDomain);
    }

    private ContractAppendixEntity toEntity(ContractAppendix appendix) {
        ContractAppendixEntity entity = new ContractAppendixEntity();
        entity.setId(appendix.getId());
        entity.setTenantId(appendix.getTenantId());
        entity.setContractId(appendix.getContractId());
        entity.setEffectiveDate(appendix.getEffectiveDate());
        entity.setNewRentPrice(appendix.getNewRentPrice());
        entity.setAppendixType(appendix.getAppendixType());
        entity.setMetadata(appendix.getMetadata());
        entity.setNewServicePrices(appendix.getNewServicePrices());
        entity.setCreatedBy(appendix.getCreatedBy());
        entity.setCreatedAt(appendix.getCreatedAt());
        return entity;
    }

    private ContractAppendix toDomain(ContractAppendixEntity entity) {
        ContractAppendix appendix = new ContractAppendix();
        appendix.setId(entity.getId());
        appendix.setTenantId(entity.getTenantId());
        appendix.setContractId(entity.getContractId());
        appendix.setEffectiveDate(entity.getEffectiveDate());
        appendix.setNewRentPrice(entity.getNewRentPrice());
        appendix.setAppendixType(entity.getAppendixType());
        appendix.setNewServicePrices(entity.getNewServicePrices());
        appendix.setMetadata(entity.getMetadata());
        appendix.setCreatedBy(entity.getCreatedBy());
        appendix.setCreatedAt(entity.getCreatedAt());
        return appendix;
    }
}

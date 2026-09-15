package com.roomrental.modules.contract.infrastructure.adapter;

import com.roomrental.modules.contract.domain.model.ContractResident;
import com.roomrental.modules.contract.domain.repository.ContractResidentRepository;
import com.roomrental.modules.contract.infrastructure.persistence.ContractResidentEntity;
import com.roomrental.modules.contract.infrastructure.persistence.ContractResidentJpaRepository;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class ContractResidentRepositoryAdapter implements ContractResidentRepository {
    private final ContractResidentJpaRepository jpaRepository;

    public ContractResidentRepositoryAdapter(ContractResidentJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public List<ContractResident> saveAll(List<ContractResident> residents) {
        List<ContractResidentEntity> entities = residents.stream().map(this::toEntity).toList();
        return jpaRepository.saveAll(entities).stream().map(this::toDomain).toList();
    }

    @Override
    public List<ContractResident> findByContractId(Long contractId) {
        return jpaRepository.findByContractId(contractId).stream().map(this::toDomain).toList();
    }

    private ContractResidentEntity toEntity(ContractResident resident) {
        ContractResidentEntity entity = new ContractResidentEntity();
        entity.setContractId(resident.getContractId());
        entity.setResidentUserId(resident.getResidentUserId());
        entity.setTenantId(resident.getTenantId());
        entity.setIsActive(resident.isActive());
        entity.setJoinedAt(resident.getJoinedAt());
        entity.setLeftAt(resident.getLeftAt());
        return entity;
    }

    private ContractResident toDomain(ContractResidentEntity entity) {
        ContractResident resident = new ContractResident();
        resident.setContractId(entity.getContractId());
        resident.setResidentUserId(entity.getResidentUserId());
        resident.setTenantId(entity.getTenantId());
        resident.setActive(entity.getIsActive());
        resident.setJoinedAt(entity.getJoinedAt());
        resident.setLeftAt(entity.getLeftAt());
        return resident;
    }
}

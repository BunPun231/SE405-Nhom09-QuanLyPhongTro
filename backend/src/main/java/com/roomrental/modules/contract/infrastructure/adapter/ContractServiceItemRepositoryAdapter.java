package com.roomrental.modules.contract.infrastructure.adapter;

import com.roomrental.modules.contract.domain.model.ContractServiceItem;
import com.roomrental.modules.contract.domain.repository.ContractServiceItemRepository;
import com.roomrental.modules.contract.infrastructure.persistence.ContractServiceItemEntity;
import com.roomrental.modules.contract.infrastructure.persistence.ContractServiceItemJpaRepository;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class ContractServiceItemRepositoryAdapter implements ContractServiceItemRepository {
    private final ContractServiceItemJpaRepository jpaRepository;

    public ContractServiceItemRepositoryAdapter(ContractServiceItemJpaRepository jpaRepository) {
        this.jpaRepository = jpaRepository;
    }

    @Override
    public List<ContractServiceItem> saveAll(List<ContractServiceItem> items) {
        List<ContractServiceItemEntity> entities = items.stream().map(this::toEntity).toList();
        List<ContractServiceItemEntity> saved = jpaRepository.saveAll(entities);
        jpaRepository.flush();
        return saved.stream().map(this::toDomain).toList();
    }

    @Override
    public List<ContractServiceItem> findByContractId(Long contractId) {
        return jpaRepository.findByContractId(contractId).stream().map(this::toDomain).toList();
    }

    private ContractServiceItemEntity toEntity(ContractServiceItem item) {
        ContractServiceItemEntity entity = new ContractServiceItemEntity();
        entity.setContractId(item.getContractId());
        entity.setServiceId(item.getServiceId());
        entity.setTenantId(item.getTenantId());
        entity.setQuantity(item.getQuantity());
        return entity;
    }

    private ContractServiceItem toDomain(ContractServiceItemEntity entity) {
        ContractServiceItem item = new ContractServiceItem();
        item.setContractId(entity.getContractId());
        item.setServiceId(entity.getServiceId());
        item.setTenantId(entity.getTenantId());
        item.setQuantity(entity.getQuantity());
        return item;
    }
}

package com.roomrental.modules.contract.infrastructure.persistence;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContractServiceItemJpaRepository extends JpaRepository<ContractServiceItemEntity, ContractServiceItemId> {
    List<ContractServiceItemEntity> findByContractId(Long contractId);
}

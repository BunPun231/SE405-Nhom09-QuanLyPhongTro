package com.roomrental.modules.contract.infrastructure.persistence;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ContractResidentJpaRepository extends JpaRepository<ContractResidentEntity, ContractResidentId> {
    List<ContractResidentEntity> findByContractId(Long contractId);
}

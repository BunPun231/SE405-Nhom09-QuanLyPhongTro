package com.roomrental.modules.contract.domain.repository;

import com.roomrental.modules.contract.domain.model.ContractResident;
import java.util.List;

/**
 * Port interface for contract resident persistence.
 */
public interface ContractResidentRepository {
    List<ContractResident> saveAll(List<ContractResident> residents);

    List<ContractResident> findByContractId(Long contractId);
}

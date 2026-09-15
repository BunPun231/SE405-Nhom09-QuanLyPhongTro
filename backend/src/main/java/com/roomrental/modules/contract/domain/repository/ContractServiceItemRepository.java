package com.roomrental.modules.contract.domain.repository;

import com.roomrental.modules.contract.domain.model.ContractServiceItem;
import java.util.List;

/**
 * Port interface for contract service items.
 */
public interface ContractServiceItemRepository {
    List<ContractServiceItem> saveAll(List<ContractServiceItem> items);

    List<ContractServiceItem> findByContractId(Long contractId);
}

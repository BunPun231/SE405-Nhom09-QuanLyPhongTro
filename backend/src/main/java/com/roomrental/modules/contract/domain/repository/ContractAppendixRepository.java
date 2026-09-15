package com.roomrental.modules.contract.domain.repository;

import com.roomrental.modules.contract.domain.model.ContractAppendix;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Port interface for contract appendix persistence.
 */
public interface ContractAppendixRepository {
    ContractAppendix save(ContractAppendix appendix);

    List<ContractAppendix> findByContractId(Long contractId);

    Page<ContractAppendix> findByContractId(Long contractId, Pageable pageable);

    long countByContractId(Long contractId);

    Optional<ContractAppendix> findById(Long id);
}

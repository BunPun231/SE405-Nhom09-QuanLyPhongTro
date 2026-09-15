package com.roomrental.modules.contract.infrastructure.persistence;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/**
 * Composite ID class cho ContractResidentEntity.
 */
public class ContractResidentId implements Serializable {
    private Long contractId;
    private UUID residentUserId;

    public ContractResidentId() {
    }

    public ContractResidentId(Long contractId, UUID residentUserId) {
        this.contractId = contractId;
        this.residentUserId = residentUserId;
    }

    public Long getContractId() {
        return contractId;
    }

    public void setContractId(Long contractId) {
        this.contractId = contractId;
    }

    public UUID getResidentUserId() {
        return residentUserId;
    }

    public void setResidentUserId(UUID residentUserId) {
        this.residentUserId = residentUserId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ContractResidentId that)) return false;
        return Objects.equals(contractId, that.contractId) &&
               Objects.equals(residentUserId, that.residentUserId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(contractId, residentUserId);
    }
}

package com.roomrental.modules.contract.infrastructure.persistence;

import java.io.Serializable;
import java.util.Objects;

public class ContractServiceItemId implements Serializable {
    private Long contractId;
    private Long serviceId;

    public ContractServiceItemId() {
    }

    public ContractServiceItemId(Long contractId, Long serviceId) {
        this.contractId = contractId;
        this.serviceId = serviceId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        ContractServiceItemId that = (ContractServiceItemId) o;
        return Objects.equals(contractId, that.contractId) && Objects.equals(serviceId, that.serviceId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(contractId, serviceId);
    }
}

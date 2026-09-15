package com.roomrental.modules.contract.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import org.springframework.data.domain.Persistable;
import java.util.UUID;

/**
 * JPA entity for contract service items.
 */
@Entity
@Table(name = "contract_service_items")
@IdClass(ContractServiceItemId.class)
public class ContractServiceItemEntity implements Persistable<ContractServiceItemId> {
    @Id
    @Column(name = "contract_id")
    private Long contractId;

    @Id
    @Column(name = "service_id")
    private Long serviceId;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    public Long getContractId() {
        return contractId;
    }

    public void setContractId(Long contractId) {
        this.contractId = contractId;
    }

    public Long getServiceId() {
        return serviceId;
    }

    public void setServiceId(Long serviceId) {
        this.serviceId = serviceId;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(UUID tenantId) {
        this.tenantId = tenantId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    @Override
    public ContractServiceItemId getId() {
        return new ContractServiceItemId(contractId, serviceId);
    }

    @Override
    public boolean isNew() {
        return true;
    }
}

package com.roomrental.modules.contract.infrastructure.persistence;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * JPA Entity cho ContractResident (bảng contract_residents).
 */
@Entity
@Table(name = "contract_residents")
@IdClass(ContractResidentId.class)
public class ContractResidentEntity {
    @Id
    @Column(name = "contract_id")
    private Long contractId;

    @Id
    @Column(name = "resident_user_id")
    private UUID residentUserId;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;

    @Column(name = "left_at")
    private LocalDateTime leftAt;

    // Constructors
    public ContractResidentEntity() {
    }

    public ContractResidentEntity(Long contractId, UUID residentUserId) {
        this.contractId = contractId;
        this.residentUserId = residentUserId;
        this.isActive = true;
        this.joinedAt = LocalDateTime.now();
    }

    // Getters & Setters
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

    public UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(UUID tenantId) {
        this.tenantId = tenantId;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(LocalDateTime joinedAt) {
        this.joinedAt = joinedAt;
    }

    public LocalDateTime getLeftAt() {
        return leftAt;
    }

    public void setLeftAt(LocalDateTime leftAt) {
        this.leftAt = leftAt;
    }
}

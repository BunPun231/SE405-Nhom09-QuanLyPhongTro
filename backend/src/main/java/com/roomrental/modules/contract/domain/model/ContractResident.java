package com.roomrental.modules.contract.domain.model;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Domain model cho Cư dân thuê phòng (thành viên hợp đồng).
 */
public class ContractResident {
    private Long contractId;
    private UUID tenantId;
    private UUID residentUserId;
    private boolean isActive;
    private LocalDateTime joinedAt;
    private LocalDateTime leftAt;

    // Constructors
    public ContractResident() {
    }

    public ContractResident(Long contractId, UUID residentUserId, boolean isActive) {
        this.contractId = contractId;
        this.residentUserId = residentUserId;
        this.isActive = isActive;
    }

    // Getters & Setters
    public Long getContractId() {
        return contractId;
    }

    public void setContractId(Long contractId) {
        this.contractId = contractId;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(UUID tenantId) {
        this.tenantId = tenantId;
    }

    public UUID getResidentUserId() {
        return residentUserId;
    }

    public void setResidentUserId(UUID residentUserId) {
        this.residentUserId = residentUserId;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
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

    // Business methods
    public void markAsLeft() {
        this.isActive = false;
        this.leftAt = LocalDateTime.now();
    }
}

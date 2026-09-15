package com.roomrental.modules.finance.infrastructure.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "resident_balances")
public class ResidentBalanceEntity {
    
    @Id
    @Column(name = "resident_user_id")
    private UUID residentUserId;

    @Column(name = "balance", nullable = false)
    private BigDecimal balance;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public UUID getResidentUserId() {
        return residentUserId;
    }

    public void setResidentUserId(UUID residentUserId) {
        this.residentUserId = residentUserId;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    public void setBalance(BigDecimal balance) {
        this.balance = balance;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}

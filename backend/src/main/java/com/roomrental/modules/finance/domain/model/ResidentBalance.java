package com.roomrental.modules.finance.domain.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ResidentBalance {
    private UUID residentUserId;
    private BigDecimal balance;
    private OffsetDateTime updatedAt;

    public ResidentBalance() {
        this.balance = BigDecimal.ZERO;
    }

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

    public void addBalance(BigDecimal amount) {
        if (amount != null && amount.compareTo(BigDecimal.ZERO) > 0) {
            this.balance = this.balance.add(amount);
            this.updatedAt = OffsetDateTime.now();
        }
    }

    public void deductBalance(BigDecimal amount) {
        if (amount != null && amount.compareTo(BigDecimal.ZERO) > 0) {
            this.balance = this.balance.subtract(amount);
            this.updatedAt = OffsetDateTime.now();
        }
    }
}

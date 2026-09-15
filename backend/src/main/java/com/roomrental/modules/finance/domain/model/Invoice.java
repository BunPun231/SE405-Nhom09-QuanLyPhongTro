package com.roomrental.modules.finance.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class Invoice {
    private Long id;
    private Long version;
    private UUID tenantId;
    private Long contractId;
    private Long roomId;
    private LocalDate billingMonth;
    private BigDecimal totalAmount;
    private BigDecimal paidAmount;
    private BigDecimal balanceDeduction;
    private InvoiceStatus status;
    private InvoiceType invoiceType;
    private String cancelReason;
    private boolean isDeleted;
    private LocalDate dueDate;
    private String calculationSnapshot;
    private List<InvoiceDetail> details = new ArrayList<>();
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public Invoice() {
        this.totalAmount = BigDecimal.ZERO;
        this.paidAmount = BigDecimal.ZERO;
        this.balanceDeduction = BigDecimal.ZERO;
        this.isDeleted = false;
        this.status = InvoiceStatus.PENDING;
        this.invoiceType = InvoiceType.MONTHLY;
    }

    public enum InvoiceStatus {
        PENDING, PARTIAL, PAID, VOID
    }

    public enum InvoiceType {
        MONTHLY, SETTLEMENT
    }

    public BigDecimal getRemainingAmount() {
        BigDecimal totalPaid = paidAmount != null ? paidAmount : BigDecimal.ZERO;
        BigDecimal deduction = balanceDeduction != null ? balanceDeduction : BigDecimal.ZERO;
        BigDecimal total = totalAmount != null ? totalAmount : BigDecimal.ZERO;
        return total.subtract(totalPaid).subtract(deduction);
    }

    public boolean canBeVoided() {
        return this.status == InvoiceStatus.PENDING;
    }

    public boolean canBeDeleted() {
        return this.status == InvoiceStatus.PENDING && 
               (this.paidAmount == null || this.paidAmount.compareTo(BigDecimal.ZERO) == 0);
    }

    public BigDecimal applyPayment(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) return BigDecimal.ZERO;
        
        BigDecimal remainingBefore = getRemainingAmount();
        BigDecimal actualApplied = amount;
        BigDecimal overpaid = BigDecimal.ZERO;

        if (amount.compareTo(remainingBefore) > 0) {
            actualApplied = remainingBefore;
            overpaid = amount.subtract(remainingBefore);
        }

        if (this.paidAmount == null) this.paidAmount = BigDecimal.ZERO;
        this.paidAmount = this.paidAmount.add(actualApplied);
        
        BigDecimal remainingAfter = getRemainingAmount();
        if (remainingAfter.compareTo(BigDecimal.ZERO) <= 0) {
            this.status = InvoiceStatus.PAID;
        } else {
            this.status = InvoiceStatus.PARTIAL;
        }

        return overpaid;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }
    public UUID getTenantId() { return tenantId; }
    public void setTenantId(UUID tenantId) { this.tenantId = tenantId; }
    public Long getContractId() { return contractId; }
    public void setContractId(Long contractId) { this.contractId = contractId; }
    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }
    public LocalDate getBillingMonth() { return billingMonth; }
    public void setBillingMonth(LocalDate billingMonth) { this.billingMonth = billingMonth; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    public BigDecimal getPaidAmount() { return paidAmount; }
    public void setPaidAmount(BigDecimal paidAmount) { this.paidAmount = paidAmount; }
    public BigDecimal getBalanceDeduction() { return balanceDeduction; }
    public void setBalanceDeduction(BigDecimal balanceDeduction) { this.balanceDeduction = balanceDeduction; }
    public InvoiceStatus getStatus() { return status; }
    public void setStatus(InvoiceStatus status) { this.status = status; }
    public InvoiceType getInvoiceType() { return invoiceType; }
    public void setInvoiceType(InvoiceType invoiceType) { this.invoiceType = invoiceType; }
    public String getCancelReason() { return cancelReason; }
    public void setCancelReason(String cancelReason) { this.cancelReason = cancelReason; }
    public boolean isDeleted() { return isDeleted; }
    public void setDeleted(boolean deleted) { isDeleted = deleted; }
    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }
    public String getCalculationSnapshot() { return calculationSnapshot; }
    public void setCalculationSnapshot(String calculationSnapshot) { this.calculationSnapshot = calculationSnapshot; }
    public List<InvoiceDetail> getDetails() { return details; }
    public void setDetails(List<InvoiceDetail> details) { this.details = details; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}


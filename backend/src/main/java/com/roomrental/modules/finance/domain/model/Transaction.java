package com.roomrental.modules.finance.domain.model;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class Transaction {
    private Long id;
    private UUID tenantId;
    private Long invoiceId;
    private BigDecimal amount;
    private String transactionRef;
    private PaymentMethod paymentMethod;
    private String bankCode;
    private TransactionStatus status;
    private OffsetDateTime paidAt;
    private String rawWebhookData;
    private OffsetDateTime createdAt;
    private BigDecimal overpaidAmount;
    private BigDecimal creditBalanceSnapshot;

    public Transaction() {}

    public enum PaymentMethod {
        VIETQR, CASH, BANK_TRANSFER
    }

    public enum TransactionStatus {
        SUCCESS, FAILED, PENDING_RECONCILE
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public UUID getTenantId() { return tenantId; }
    public void setTenantId(UUID tenantId) { this.tenantId = tenantId; }
    public Long getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Long invoiceId) { this.invoiceId = invoiceId; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getTransactionRef() { return transactionRef; }
    public void setTransactionRef(String transactionRef) { this.transactionRef = transactionRef; }
    public PaymentMethod getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(PaymentMethod paymentMethod) { this.paymentMethod = paymentMethod; }
    public String getBankCode() { return bankCode; }
    public void setBankCode(String bankCode) { this.bankCode = bankCode; }
    public TransactionStatus getStatus() { return status; }
    public void setStatus(TransactionStatus status) { this.status = status; }
    public OffsetDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(OffsetDateTime paidAt) { this.paidAt = paidAt; }
    public String getRawWebhookData() { return rawWebhookData; }
    public void setRawWebhookData(String rawWebhookData) { this.rawWebhookData = rawWebhookData; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
    public BigDecimal getOverpaidAmount() { return overpaidAmount; }
    public void setOverpaidAmount(BigDecimal overpaidAmount) { this.overpaidAmount = overpaidAmount; }
    public BigDecimal getCreditBalanceSnapshot() { return creditBalanceSnapshot; }
    public void setCreditBalanceSnapshot(BigDecimal creditBalanceSnapshot) { this.creditBalanceSnapshot = creditBalanceSnapshot; }
}

package com.roomrental.modules.contract.infrastructure.persistence;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * JPA Entity cho Contract (bảng contracts).
 */
@Entity
@Table(name = "contracts")
public class ContractEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "primary_resident_user_id", nullable = false)
    private UUID primaryResidentUserId;

    @Column(name = "rent_price", nullable = false, precision = 12, scale = 2)
    private BigDecimal rentPrice;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "deposit_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal depositAmount;

    @Column(name = "deposit_status", nullable = false)
    private String depositStatus;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "billing_date")
    private LocalDate billingDate;

    @Column(name = "billing_cycle_day")
    private Integer billingCycleDay;

    @Column(name = "payment_cycle_months")
    private Integer paymentCycleMonths;

    @Column(name = "intended_move_out_date")
    private LocalDate intendedMoveOutDate;

    @Column(name = "pdf_url")
    private String pdfUrl;

    @Column(name = "cancel_reason")
    private String cancelReason;

    @Column(name = "move_out_reason")
    private String moveOutReason;

    @Column(name = "credit_balance", precision = 12, scale = 2)
    private BigDecimal creditBalance;

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Constructors
    public ContractEntity() {
    }

    // Getters & Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getVersion() {
        return version;
    }

    public void setVersion(Long version) {
        this.version = version;
    }

    public UUID getTenantId() {
        return tenantId;
    }

    public void setTenantId(UUID tenantId) {
        this.tenantId = tenantId;
    }

    public Long getRoomId() {
        return roomId;
    }

    public void setRoomId(Long roomId) {
        this.roomId = roomId;
    }

    public UUID getPrimaryResidentUserId() {
        return primaryResidentUserId;
    }

    public void setPrimaryResidentUserId(UUID primaryResidentUserId) {
        this.primaryResidentUserId = primaryResidentUserId;
    }

    public BigDecimal getRentPrice() {
        return rentPrice;
    }

    public void setRentPrice(BigDecimal rentPrice) {
        this.rentPrice = rentPrice;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public BigDecimal getDepositAmount() {
        return depositAmount;
    }

    public void setDepositAmount(BigDecimal depositAmount) {
        this.depositAmount = depositAmount;
    }

    public String getDepositStatus() {
        return depositStatus;
    }

    public void setDepositStatus(String depositStatus) {
        this.depositStatus = depositStatus;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDate getBillingDate() {
        return billingDate;
    }

    public void setBillingDate(LocalDate billingDate) {
        this.billingDate = billingDate;
    }

    public Integer getBillingCycleDay() {
        return billingCycleDay;
    }

    public void setBillingCycleDay(Integer billingCycleDay) {
        this.billingCycleDay = billingCycleDay;
    }

    public Integer getPaymentCycleMonths() {
        return paymentCycleMonths;
    }

    public void setPaymentCycleMonths(Integer paymentCycleMonths) {
        this.paymentCycleMonths = paymentCycleMonths;
    }

    public LocalDate getIntendedMoveOutDate() {
        return intendedMoveOutDate;
    }

    public void setIntendedMoveOutDate(LocalDate intendedMoveOutDate) {
        this.intendedMoveOutDate = intendedMoveOutDate;
    }

    public String getPdfUrl() {
        return pdfUrl;
    }

    public void setPdfUrl(String pdfUrl) {
        this.pdfUrl = pdfUrl;
    }

    public String getCancelReason() {
        return cancelReason;
    }

    public void setCancelReason(String cancelReason) {
        this.cancelReason = cancelReason;
    }

    public String getMoveOutReason() {
        return moveOutReason;
    }

    public void setMoveOutReason(String moveOutReason) {
        this.moveOutReason = moveOutReason;
    }

    public BigDecimal getCreditBalance() {
        return creditBalance;
    }

    public void setCreditBalance(BigDecimal creditBalance) {
        this.creditBalance = creditBalance;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(UUID createdBy) {
        this.createdBy = createdBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}

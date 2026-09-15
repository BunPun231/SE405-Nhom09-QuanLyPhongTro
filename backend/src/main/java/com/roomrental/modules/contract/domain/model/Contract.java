package com.roomrental.modules.contract.domain.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Domain model cho Hợp đồng thuê phòng.
 * Pure POJO, không phụ thuộc JPA.
 */
public class Contract {
    private Long id;
    private Long version;
    private UUID tenantId;
    private Long roomId;
    private UUID primaryResidentUserId;
    private BigDecimal rentPrice;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal depositAmount;
    private DepositStatus depositStatus;
    private ContractStatus status;
    private LocalDate billingDate;
    private Integer billingCycleDay;
    private Integer paymentCycleMonths;
    private LocalDate intendedMoveOutDate;
    private String pdfUrl;
    private String cancelReason;
    private String moveOutReason;
    private List<ContractAppendix> appendixes = new ArrayList<>();
    private UUID createdBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Constructors
    public Contract() {
    }

    public Contract(Long id, UUID tenantId, Long roomId, UUID primaryResidentUserId,
                   LocalDate startDate, LocalDate endDate, BigDecimal depositAmount,
                   DepositStatus depositStatus, ContractStatus status) {
        this.id = id;
        this.tenantId = tenantId;
        this.roomId = roomId;
        this.primaryResidentUserId = primaryResidentUserId;
        this.startDate = startDate;
        this.endDate = endDate;
        this.depositAmount = depositAmount;
        this.depositStatus = depositStatus;
        this.status = status;
    }

    // Enum for contract status
    public enum ContractStatus {
        DRAFT,                    // Nháp
        ACTIVE,                   // Đang hiệu lực
        LIQUIDATED,               // Đã tất toán
        CANCELED,                 // Đã hủy
        PENDING_LIQUIDATION       // Chờ tất toán
    }

    // Enum for deposit status
    public enum DepositStatus {
        UNPAID,                   // Chưa thu cọc
        PAID,                     // Đã thu cọc
        REFUNDED,                 // Đã hoàn cọc
        DEDUCTED                  // Đã trừ vào phí tổn thất
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

    public DepositStatus getDepositStatus() {
        return depositStatus;
    }

    public void setDepositStatus(DepositStatus depositStatus) {
        this.depositStatus = depositStatus;
    }

    public ContractStatus getStatus() {
        return status;
    }

    public void setStatus(ContractStatus status) {
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

    public List<ContractAppendix> getAppendixes() {
        return appendixes;
    }

    public void setAppendixes(List<ContractAppendix> appendixes) {
        this.appendixes = appendixes;
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

    // Business methods
    public boolean isActive() {
        return status == ContractStatus.ACTIVE;
    }

    public boolean canBeLiquidated() {
        return status == ContractStatus.ACTIVE || status == ContractStatus.PENDING_LIQUIDATION;
    }

    public void activate() {
        this.status = ContractStatus.ACTIVE;
    }

    public void markForLiquidation() {
        if (canBeLiquidated()) {
            this.status = ContractStatus.PENDING_LIQUIDATION;
        }
    }

    public void liquidate() {
        if (canBeLiquidated()) {
            this.status = ContractStatus.LIQUIDATED;
        }
    }
}

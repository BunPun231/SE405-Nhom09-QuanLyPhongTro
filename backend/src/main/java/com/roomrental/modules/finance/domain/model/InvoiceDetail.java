package com.roomrental.modules.finance.domain.model;

import java.math.BigDecimal;

public class InvoiceDetail {
    private Long id;
    private Long invoiceId;
    private String description;
    private BigDecimal quantity;
    private BigDecimal unitPrice;
    private BigDecimal lineTotal;
    private Long serviceId;

    public InvoiceDetail() {}

    public InvoiceDetail(String description, BigDecimal quantity, BigDecimal unitPrice, Long serviceId) {
        this.description = description;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.serviceId = serviceId;
        this.lineTotal = quantity.multiply(unitPrice);
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Long invoiceId) { this.invoiceId = invoiceId; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public BigDecimal getQuantity() { return quantity; }
    public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    public BigDecimal getLineTotal() { return lineTotal; }
    public void setLineTotal(BigDecimal lineTotal) { this.lineTotal = lineTotal; }
    public Long getServiceId() { return serviceId; }
    public void setServiceId(Long serviceId) { this.serviceId = serviceId; }
}

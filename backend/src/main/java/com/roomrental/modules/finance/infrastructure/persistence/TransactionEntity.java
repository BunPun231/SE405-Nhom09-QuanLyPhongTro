package com.roomrental.modules.finance.infrastructure.persistence;

import com.roomrental.modules.finance.domain.model.Transaction.PaymentMethod;
import com.roomrental.modules.finance.domain.model.Transaction.TransactionStatus;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import org.springframework.data.annotation.CreatedDate;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "transactions")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
public class TransactionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(name = "invoice_id")
    private Long invoiceId;

    @Column(name = "amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Column(name = "transaction_ref", unique = true)
    private String transactionRef;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method")
    private PaymentMethod paymentMethod;

    @Column(name = "bank_code")
    private String bankCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private TransactionStatus status;

    @Column(name = "paid_at")
    private OffsetDateTime paidAt;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "raw_webhook_data", columnDefinition = "jsonb")
    private String rawWebhookData;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "overpaid_amount")
    private BigDecimal overpaidAmount;
}

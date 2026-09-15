package com.roomrental.modules.finance.interfaces.rest.controller;

import com.roomrental.modules.finance.application.dto.*;
import com.roomrental.modules.finance.application.service.PaymentService;
import com.roomrental.modules.finance.interfaces.rest.dto.PaymentManualRequest;
import com.roomrental.modules.finance.interfaces.rest.dto.WebhookSimulateRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/payments")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Finance - Payments", description = "UC78, UC79")
public class PaymentController {

    private final PaymentService service;

    public PaymentController(PaymentService service) {
        this.service = service;
    }

    @PostMapping("/test/webhook-simulate")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Simulate a VietQR Webhook payload (UC78 Mock)")
    public ResponseEntity<TransactionResult> simulateWebhook(@RequestBody @Valid WebhookSimulateRequest request) {
        PaymentWebhookCommand cmd = new PaymentWebhookCommand(
            request.transactionRef(), request.amount(), request.bankCode(), request.memo(), request.rawData()
        );
        return ResponseEntity.ok(service.processWebhook(cmd));
    }

    @PostMapping("/manual")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Process manual payment like cash (UC78)")
    public ResponseEntity<TransactionResult> processManualPayment(@RequestBody @Valid PaymentManualRequest request) {
        PaymentManualCommand cmd = new PaymentManualCommand(
            request.invoiceId(), request.amount(), request.paymentMethod()
        );
        return ResponseEntity.ok(service.processManualPayment(cmd));
    }

    @PostMapping("/reconcile")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Manually reconcile a pending transaction (UC79)")
    public ResponseEntity<TransactionResult> reconcileTransaction(@RequestBody @Valid com.roomrental.modules.finance.interfaces.rest.dto.PaymentReconcileRequest request) {
        PaymentReconcileCommand cmd = new PaymentReconcileCommand(
            request.transactionId(), request.invoiceId()
        );
        return ResponseEntity.ok(service.reconcileTransaction(cmd));
    }

    @GetMapping("/transactions")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Get transaction history (UC79)")
    public ResponseEntity<Page<TransactionResult>> getTransactions(Pageable pageable) {
        return ResponseEntity.ok(service.getTransactions(pageable));
    }
}

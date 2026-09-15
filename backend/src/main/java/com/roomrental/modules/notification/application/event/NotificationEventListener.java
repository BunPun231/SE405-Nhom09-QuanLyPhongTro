package com.roomrental.modules.notification.application.event;

import com.roomrental.modules.auth.domain.model.Tenant;
import com.roomrental.modules.auth.domain.repository.TenantRepository;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.finance.application.event.InvoiceCreatedEvent;
import com.roomrental.modules.finance.application.event.PaymentReceivedEvent;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import com.roomrental.modules.notification.application.service.NotificationService;
import com.roomrental.modules.notification.domain.model.NotificationType;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.UUID;

@Component
public class NotificationEventListener {

    private static final Logger log = LoggerFactory.getLogger(NotificationEventListener.class);

    private final NotificationService notificationService;
    private final InvoiceRepository invoiceRepository;
    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final TenantRepository tenantRepository;

    public NotificationEventListener(
            NotificationService notificationService,
            InvoiceRepository invoiceRepository,
            ContractRepository contractRepository,
            RoomRepository roomRepository,
            TenantRepository tenantRepository) {
        this.notificationService = notificationService;
        this.invoiceRepository = invoiceRepository;
        this.contractRepository = contractRepository;
        this.roomRepository = roomRepository;
        this.tenantRepository = tenantRepository;
    }

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void handleInvoiceCreatedEvent(InvoiceCreatedEvent event) {
        log.info("Handling InvoiceCreatedEvent asynchronously for invoice ID: {}", event.invoiceId());
        try {
            Invoice invoice = invoiceRepository.findById(event.invoiceId()).orElse(null);
            if (invoice == null) {
                log.warn("Invoice not found for ID: {}, notification creation skipped", event.invoiceId());
                return;
            }

            Contract contract = contractRepository.findById(invoice.getContractId()).orElse(null);
            if (contract == null) {
                log.warn("Contract not found for ID: {}, notification creation skipped", invoice.getContractId());
                return;
            }

            Room room = roomRepository.findById(invoice.getRoomId()).orElse(null);
            String roomNum = room != null ? room.getRoomNumber() : "N/A";

            UUID residentUserId = contract.getPrimaryResidentUserId();
            String title = "Hóa đơn mới được phát hành";
            String content = String.format("Hóa đơn tháng %s cho phòng %s đã được phát hành. Tổng số tiền: %,.0f VND. Hạn thanh toán: %s.",
                    invoice.getBillingMonth() != null ? invoice.getBillingMonth().toString() : "",
                    roomNum,
                    invoice.getTotalAmount(),
                    invoice.getDueDate() != null ? invoice.getDueDate().toString() : "N/A");
            String actionUrl = "/resident/invoices/" + event.invoiceId();

            notificationService.createNotification(event.tenantId(), residentUserId, title, content, NotificationType.BILLING, actionUrl);
            log.info("Sent billing notification to resident user ID: {}", residentUserId);

        } catch (Exception e) {
            log.error("Error processing InvoiceCreatedEvent", e);
        }
    }

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void handlePaymentReceivedEvent(PaymentReceivedEvent event) {
        log.info("Handling PaymentReceivedEvent asynchronously for transaction ID: {}, invoice ID: {}", event.transactionId(), event.invoiceId());
        try {
            Invoice invoice = invoiceRepository.findById(event.invoiceId()).orElse(null);
            if (invoice == null) {
                log.warn("Invoice not found for ID: {}, notification creation skipped", event.invoiceId());
                return;
            }

            Contract contract = contractRepository.findById(invoice.getContractId()).orElse(null);
            if (contract == null) {
                log.warn("Contract not found for ID: {}, notification creation skipped", invoice.getContractId());
                return;
            }

            Room room = roomRepository.findById(invoice.getRoomId()).orElse(null);
            String roomNum = room != null ? room.getRoomNumber() : "N/A";

            // 1. Notify Resident (Tenant)
            UUID residentUserId = contract.getPrimaryResidentUserId();
            String tenantTitle = "Xác nhận thanh toán thành công";
            String tenantContent = String.format("Bạn đã thanh toán thành công số tiền %s VND cho hóa đơn tháng %s.",
                    event.amount(),
                    invoice.getBillingMonth() != null ? invoice.getBillingMonth().toString() : "");
            String tenantActionUrl = "/resident/invoices/" + event.invoiceId();

            notificationService.createNotification(event.tenantId(), residentUserId, tenantTitle, tenantContent, NotificationType.PAYMENT, tenantActionUrl);
            log.info("Sent payment confirmation notification to resident user ID: {}", residentUserId);

            // 2. Notify Landlord (Tenant Owner)
            Tenant tenant = tenantRepository.findById(event.tenantId()).orElse(null);
            if (tenant != null) {
                UUID ownerUserId = tenant.getOwnerUserId();
                String ownerTitle = "Thanh toán hóa đơn thành công";
                String ownerContent = String.format("Phòng %s đã thanh toán thành công số tiền %s VND cho hóa đơn tháng %s.",
                        roomNum,
                        event.amount(),
                        invoice.getBillingMonth() != null ? invoice.getBillingMonth().toString() : "");
                String ownerActionUrl = "/manager/invoices/" + event.invoiceId();

                notificationService.createNotification(event.tenantId(), ownerUserId, ownerTitle, ownerContent, NotificationType.PAYMENT, ownerActionUrl);
                log.info("Sent payment received notification to landlord user ID: {}", ownerUserId);
            } else {
                log.warn("Tenant workspace not found for ID: {}, landlord notification skipped", event.tenantId());
            }

        } catch (Exception e) {
            log.error("Error processing PaymentReceivedEvent", e);
        }
    }
}

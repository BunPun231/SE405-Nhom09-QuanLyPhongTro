package com.roomrental.modules.finance.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.contract.domain.repository.ContractServiceItemRepository;
import com.roomrental.modules.finance.application.dto.InvoiceAdjustCommand;
import com.roomrental.modules.finance.application.dto.InvoiceResult;
import com.roomrental.modules.finance.application.strategy.BillingStrategyFactory;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.model.ResidentBalance;
import com.roomrental.modules.finance.domain.repository.*;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("InvoiceService Unit Tests (UC74, UC76, UC77)")
class InvoiceServiceTest {

    @Mock private InvoiceRepository invoiceRepository;
    @Mock private InvoiceDetailRepository invoiceDetailRepository;
    @Mock private ContractRepository contractRepository;
    @Mock private RoomRepository roomRepository;
    @Mock private RentalServiceRepository rentalServiceRepository;
    @Mock private ServiceUsageRepository serviceUsageRepository;
    @Mock private ServicePricingRepository servicePricingRepository;
    @Mock private MeterReadingRepository meterReadingRepository;
    @Mock private ResidentBalanceRepository residentBalanceRepository;
    @Mock private BillingStrategyFactory strategyFactory;
    @Mock private ApplicationEventPublisher eventPublisher;
    @Mock private MotelRepository motelRepository;
    @Mock private ContractServiceItemRepository contractServiceItemRepository;
    @Mock private TransactionRepository transactionRepository;

    private InvoiceService service;
    private UUID tenantId;
    private UUID userId;

    @BeforeEach
    void setUp() {
        service = new InvoiceService(invoiceRepository, invoiceDetailRepository, contractRepository, roomRepository,
                rentalServiceRepository, serviceUsageRepository, servicePricingRepository, meterReadingRepository,
                residentBalanceRepository, strategyFactory, eventPublisher, new ObjectMapper(), motelRepository,
                contractServiceItemRepository, transactionRepository);
        tenantId = UUID.randomUUID();
        userId = UUID.randomUUID();
        TenantContext.setCurrentTenantId(tenantId.toString());
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userId.toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))));
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    private Invoice invoice(long id, String status, String month, long roomId, BigDecimal total, BigDecimal paid) {
        Invoice inv = new Invoice();
        inv.setId(id);
        inv.setTenantId(tenantId);
        inv.setContractId(7L);
        inv.setRoomId(roomId);
        inv.setBillingMonth(LocalDate.parse(month));
        inv.setTotalAmount(total);
        inv.setPaidAmount(paid);
        inv.setStatus(Invoice.InvoiceStatus.valueOf(status));
        return inv;
    }

    @Test
    @DisplayName("parseBillingMonth accepts yyyy-MM and yyyy-MM-dd")
    void parseBillingMonth() {
        assertThat(InvoiceService.parseBillingMonth("2026-04")).isEqualTo(LocalDate.of(2026, 4, 1));
        assertThat(InvoiceService.parseBillingMonth("2026-04-15")).isEqualTo(LocalDate.of(2026, 4, 1));
        assertThat(InvoiceService.parseBillingMonth(" ")).isNull();
        assertThatThrownBy(() -> InvoiceService.parseBillingMonth("04/2026")).isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("UC74: list filters by month and room, newest first, paged")
    void list_filtersByMonthAndRoom() {
        List<Invoice> all = List.of(
                invoice(1, "PENDING", "2026-03-01", 10, BigDecimal.TEN, BigDecimal.ZERO),
                invoice(2, "PENDING", "2026-04-01", 10, BigDecimal.TEN, BigDecimal.ZERO),
                invoice(3, "PAID", "2026-04-01", 11, BigDecimal.TEN, BigDecimal.TEN));
        when(invoiceRepository.findByTenantId(eq(tenantId), any(Pageable.class))).thenReturn(new PageImpl<>(all));
        when(contractRepository.findById(7L)).thenReturn(Optional.empty());
        when(roomRepository.findById(any())).thenReturn(Optional.empty());

        Page<InvoiceResult> page = service.list(null, null, "2026-04", 10L, PageRequest.of(0, 20));

        assertThat(page.getTotalElements()).isEqualTo(1);
        assertThat(page.getContent().get(0).id()).isEqualTo(2L);
    }

    @Test
    @DisplayName("UC76: cannot void-and-reissue an invoice that already has a payment")
    void adjust_rejectsPaidInvoice() {
        Invoice inv = invoice(5, "PARTIAL", "2026-04-01", 10, BigDecimal.valueOf(100), BigDecimal.valueOf(40));
        when(invoiceRepository.findByIdAndTenantId(5L, tenantId)).thenReturn(Optional.of(inv));

        assertThatThrownBy(() -> service.adjustInvoice(new InvoiceAdjustCommand(5L, "Sai số điện", Map.of(), Map.of())))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("đã có giao dịch");
        verify(invoiceRepository, never()).save(any());
    }

    @Test
    @DisplayName("UC76: reason is mandatory")
    void adjust_requiresReason() {
        Invoice inv = invoice(5, "PENDING", "2026-04-01", 10, BigDecimal.valueOf(100), BigDecimal.ZERO);
        when(invoiceRepository.findByIdAndTenantId(5L, tenantId)).thenReturn(Optional.of(inv));

        assertThatThrownBy(() -> service.adjustInvoice(new InvoiceAdjustCommand(5L, "  ", Map.of(), Map.of())))
                .isInstanceOf(BaseException.class);
        verify(invoiceRepository, never()).save(any());
    }

    @Test
    @DisplayName("UC77: delete blocked when a transaction exists")
    void delete_blockedByTransaction() {
        Invoice inv = invoice(6, "PENDING", "2026-04-01", 10, BigDecimal.valueOf(100), BigDecimal.ZERO);
        when(invoiceRepository.findByIdAndTenantId(6L, tenantId)).thenReturn(Optional.of(inv));
        when(transactionRepository.existsByInvoiceId(6L)).thenReturn(true);

        assertThatThrownBy(() -> service.deleteInvoice(6L, "Tạo nhầm")).isInstanceOf(BaseException.class);
        verify(invoiceRepository, never()).softDelete(any());
    }

    @Test
    @DisplayName("UC77: delete stores reason, restores balance deduction and soft-deletes")
    void delete_storesReasonAndRestoresBalance() {
        Invoice inv = invoice(6, "PENDING", "2026-04-01", 10, BigDecimal.valueOf(100), BigDecimal.ZERO);
        inv.setBalanceDeduction(BigDecimal.valueOf(30));
        UUID residentId = UUID.randomUUID();
        Contract contract = new Contract();
        contract.setId(7L);
        contract.setPrimaryResidentUserId(residentId);
        ResidentBalance rb = new ResidentBalance();
        rb.setResidentUserId(residentId);
        rb.setBalance(BigDecimal.ZERO);

        when(invoiceRepository.findByIdAndTenantId(6L, tenantId)).thenReturn(Optional.of(inv));
        when(transactionRepository.existsByInvoiceId(6L)).thenReturn(false);
        when(contractRepository.findById(7L)).thenReturn(Optional.of(contract));
        when(residentBalanceRepository.findById(residentId)).thenReturn(Optional.of(rb));

        service.deleteInvoice(6L, "Tạo nhầm phòng");

        ArgumentCaptor<Invoice> saved = ArgumentCaptor.forClass(Invoice.class);
        verify(invoiceRepository).save(saved.capture());
        assertThat(saved.getValue().getCancelReason()).isEqualTo("Tạo nhầm phòng");
        assertThat(rb.getBalance()).isEqualByComparingTo("30");
        verify(invoiceRepository).softDelete(6L);
        verifyNoInteractions(meterReadingRepository);
    }
}

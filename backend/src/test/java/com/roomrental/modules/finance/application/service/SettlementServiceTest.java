package com.roomrental.modules.finance.application.service;

import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.finance.application.dto.DamageItemInput;
import com.roomrental.modules.finance.application.strategy.BillingContext;
import com.roomrental.modules.finance.application.strategy.BillingStrategy;
import com.roomrental.modules.finance.application.strategy.BillingStrategyFactory;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.model.ResidentBalance;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.repository.InvoiceDetailRepository;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.finance.domain.repository.ResidentBalanceRepository;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.repository.TransactionRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.service.domain.model.ChargeType;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("SettlementService Unit Tests")
class SettlementServiceTest {

    @Mock private ContractRepository contractRepository;
    @Mock private InvoiceRepository invoiceRepository;
    @Mock private InvoiceDetailRepository invoiceDetailRepository;
    @Mock private RoomRepository roomRepository;
    @Mock private MeterReadingRepository meterReadingRepository;
    @Mock private ServiceUsageRepository serviceUsageRepository;
    @Mock private RentalServiceRepository rentalServiceRepository;
    @Mock private ServicePricingRepository servicePricingRepository;
    @Mock private ResidentBalanceRepository residentBalanceRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private BillingStrategyFactory strategyFactory;
    @Mock private ApplicationEventPublisher eventPublisher;
    @InjectMocks private SettlementService settlementService;

    private UUID tenantId;
    private UUID userId;

    @BeforeEach
    void setUp() {
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

    @Test
    @DisplayName("Confirm settlement cancels billable service usages")
    void confirmSettlement_cancelsServiceUsages() {
        Contract contract = new Contract();
        contract.setId(1L);
        contract.setTenantId(tenantId);
        contract.setRoomId(10L);
        contract.setPrimaryResidentUserId(UUID.randomUUID());
        contract.setRentPrice(new BigDecimal("3000000"));
        contract.setDepositAmount(BigDecimal.ZERO);
        contract.setStatus(Contract.ContractStatus.ACTIVE);

        Room room = new Room();
        room.setId(10L);
        room.setMotelId(99L);
        room.setStatus(RoomStatus.RENTED);

        ServiceUsage usage = new ServiceUsage();
        usage.setId(55L);
        usage.setRoomId(10L);
        usage.setServiceId(88L);
        usage.setStatus(ServiceUsage.ServiceUsageStatus.ACTIVE);

        RentalService service = new RentalService();
        service.setId(88L);
        service.setMotelId(99L);
        service.setName("Điện");
        service.setChargeType(ChargeType.PER_QUANTITY);

        BillingStrategy strategy = mock(BillingStrategy.class);
        when(strategyFactory.getStrategy(anyString(), anyBoolean())).thenReturn(strategy);
        when(strategy.calculate(any(BillingContext.class))).thenAnswer(inv -> {
            BillingContext ctx = inv.getArgument(0);
            BigDecimal qty = ctx.quantity() != null ? ctx.quantity() : BigDecimal.ONE;
            return List.of(new InvoiceDetail(ctx.serviceName(), qty, ctx.basePrice(), ctx.serviceId()));
        });

        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));
        when(contractRepository.findById(1L)).thenReturn(Optional.of(contract));
        when(contractRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(roomRepository.findById(10L)).thenReturn(Optional.of(room));
        when(serviceUsageRepository.findBillableByRoomId(10L)).thenReturn(List.of(usage));
        when(rentalServiceRepository.findByIdAndMotelId(88L, 99L)).thenReturn(Optional.of(service));
        when(servicePricingRepository.findCurrentByServiceId(eq(88L), any(LocalDate.class))).thenReturn(Optional.empty());
        when(invoiceRepository.findUnpaidByContractId(1L)).thenReturn(List.of());
        when(invoiceRepository.save(any(Invoice.class))).thenAnswer(inv -> {
            Invoice invoice = inv.getArgument(0);
            invoice.setId(100L);
            return invoice;
        });
        when(invoiceDetailRepository.saveAll(any())).thenAnswer(inv -> inv.getArgument(0));
        when(serviceUsageRepository.saveAll(any())).thenAnswer(inv -> inv.getArgument(0));
        when(residentBalanceRepository.findById(any())).thenReturn(Optional.empty());

        settlementService.confirmSettlement(new com.roomrental.modules.finance.application.dto.SettlementConfirmCommand(
            1L, LocalDate.of(2026, 6, 2), null, null, List.of()));

        ArgumentCaptor<List<ServiceUsage>> captor = ArgumentCaptor.forClass(List.class);
        verify(serviceUsageRepository).saveAll(captor.capture());
        assertThat(captor.getValue()).allSatisfy(saved ->
                assertThat(saved.getStatus()).isEqualTo(ServiceUsage.ServiceUsageStatus.CANCELLED));
    }
}
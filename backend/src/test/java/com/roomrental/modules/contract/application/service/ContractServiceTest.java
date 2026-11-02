package com.roomrental.modules.contract.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.contract.application.dto.ContractCreateCommand;
import com.roomrental.modules.contract.application.dto.ContractResult;
import com.roomrental.modules.contract.application.dto.DepositCollectCommand;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.model.ContractAppendix;
import com.roomrental.modules.finance.domain.model.Invoice;
import com.roomrental.modules.finance.domain.repository.InvoiceRepository;
import org.springframework.data.domain.PageImpl;
import com.roomrental.modules.contract.domain.repository.ContractAppendixRepository;
import com.roomrental.modules.contract.domain.repository.ContractResidentRepository;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.contract.domain.repository.ContractServiceItemRepository;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.resident.application.service.ResidentService;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("ContractService Unit Tests")
class ContractServiceTest {

    static {
        System.setProperty("net.bytebuddy.experimental", "true");
    }

    @Mock private ContractRepository contractRepository;
    @Mock private ContractResidentRepository contractResidentRepository;
    @Mock private ContractAppendixRepository contractAppendixRepository;
    @Mock private ContractServiceItemRepository contractServiceItemRepository;
    @Mock private RoomRepository roomRepository;
    @Mock private MotelRepository motelRepository;
    @Mock private ResidentService residentService;
    @Mock private RentalServiceRepository rentalServiceRepository;
    @Mock private com.roomrental.modules.finance.domain.repository.ServiceUsageRepository serviceUsageRepository;
    @Mock private com.roomrental.modules.finance.domain.repository.MeterReadingRepository meterReadingRepository;
    @Mock private com.roomrental.modules.contract.application.adjustment.ContractAdjustmentStrategyFactory strategyFactory;
    @Mock private org.springframework.context.ApplicationEventPublisher eventPublisher;
    @Mock private InvoiceRepository invoiceRepository;
    @InjectMocks private ContractService contractService;

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
    @DisplayName("Create contract sets tenant and createdBy")
    void create_setsTenantAndCreatedBy() {
        Room room = baseRoom();
        Motel motel = new Motel();
        motel.setId(room.getMotelId());
        motel.setTenantId(tenantId);

        when(roomRepository.findById(room.getId())).thenReturn(Optional.of(room));
        when(motelRepository.findByIdAndTenantId(room.getMotelId(), tenantId)).thenReturn(Optional.of(motel));
        when(contractRepository.existsActiveByRoomId(tenantId, room.getId())).thenReturn(false);
        when(contractRepository.save(any(Contract.class))).thenAnswer(inv -> {
            Contract c = inv.getArgument(0);
            c.setId(1L);
            return c;
        });

        ContractResult result = contractService.create(new ContractCreateCommand(
                10L,
                UUID.randomUUID().toString(),
                null,
                null,
                null,
                null,
                null,
                null,
                new BigDecimal("4500000"),
                LocalDate.of(2024, 1, 1),
                LocalDate.of(2025, 1, 1),
                new BigDecimal("5000000"),
                "UNPAID",
                null,
                30,
                1,
                List.of(),
                List.of()
        ));

        ArgumentCaptor<Contract> captor = ArgumentCaptor.forClass(Contract.class);
        verify(contractRepository).save(captor.capture());
        Contract saved = captor.getValue();

        assertThat(saved.getTenantId()).isEqualTo(tenantId);
        assertThat(saved.getCreatedBy()).isEqualTo(userId);
        assertThat(result.id()).isEqualTo(1L);
        assertThat(room.getStatus()).isEqualTo(RoomStatus.DEPOSITED);
        verify(contractResidentRepository).saveAll(any());
        verify(roomRepository).save(room);
    }

    @Test
    @DisplayName("Create contract with service items saves contract services")
    void create_withServiceItems_savesContractServices() {
        Room room = baseRoom();
        Motel motel = new Motel();
        motel.setId(room.getMotelId());
        motel.setTenantId(tenantId);

        com.roomrental.modules.service.domain.model.RentalService service = new com.roomrental.modules.service.domain.model.RentalService();
        service.setId(100L);
        service.setMotelId(room.getMotelId());
        service.setChargeType(com.roomrental.modules.service.domain.model.ChargeType.FIXED);

        when(roomRepository.findById(room.getId())).thenReturn(Optional.of(room));
        when(motelRepository.findByIdAndTenantId(room.getMotelId(), tenantId)).thenReturn(Optional.of(motel));
        when(contractRepository.existsActiveByRoomId(tenantId, room.getId())).thenReturn(false);
        when(rentalServiceRepository.findByIdAndMotelId(100L, room.getMotelId())).thenReturn(Optional.of(service));
        when(rentalServiceRepository.findByMotelIdAndMandatory(room.getMotelId(), true)).thenReturn(List.of());
        when(contractRepository.save(any(Contract.class))).thenAnswer(inv -> {
            Contract c = inv.getArgument(0);
            c.setId(1L);
            return c;
        });

        contractService.create(new ContractCreateCommand(
                10L,
                UUID.randomUUID().toString(),
                null,
                null,
                null,
                null,
                null,
                null,
                new BigDecimal("4500000"),
                LocalDate.of(2024, 1, 1),
                LocalDate.of(2025, 1, 1),
                new BigDecimal("5000000"),
                "UNPAID",
                null,
                30,
                1,
                List.of(),
                List.of(new com.roomrental.modules.contract.application.dto.ContractServiceItemCommand(100L, 1, null))
        ));

        ArgumentCaptor<List<com.roomrental.modules.contract.domain.model.ContractServiceItem>> servicesCaptor = ArgumentCaptor.forClass(List.class);
        verify(contractServiceItemRepository).saveAll(servicesCaptor.capture());
        List<com.roomrental.modules.contract.domain.model.ContractServiceItem> savedItems = servicesCaptor.getValue();

        assertThat(savedItems).hasSize(1);
        assertThat(savedItems.get(0).getServiceId()).isEqualTo(100L);
        assertThat(savedItems.get(0).getQuantity()).isEqualTo(1);
    }

    @Test
    @DisplayName("Create contract validates start/end dates")
    void create_invalidDates_throws() {
        assertThatThrownBy(() -> contractService.create(new ContractCreateCommand(
                10L,
                UUID.randomUUID().toString(),
                null,
                null,
                null,
                null,
                null,
                null,
                new BigDecimal("4500000"),
                LocalDate.of(2025, 1, 1),
                LocalDate.of(2024, 1, 1),
                new BigDecimal("5000000"),
                "UNPAID",
                null,
                30,
                1,
                List.of(),
                List.of()
        ))).isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("Activate contract only allows DRAFT")
    void activate_onlyDraft() {
        Contract contract = baseContract(1L, Contract.ContractStatus.ACTIVE);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));

        assertThatThrownBy(() -> contractService.activate(1L))
                .isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("UC67: Cancel requires a reason")
    void cancel_requiresReason() {
        Contract contract = baseContract(1L, Contract.ContractStatus.DRAFT);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));

        assertThatThrownBy(() -> contractService.cancel(1L, "  "))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("ly do");
        verify(contractRepository, never()).save(any());
    }

    @Test
    @DisplayName("UC67: Cancel is blocked when the contract has outstanding debt")
    void cancel_blockedByOutstandingDebt() {
        Contract contract = baseContract(1L, Contract.ContractStatus.ACTIVE);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));
        Invoice pending = new Invoice();
        pending.setStatus(Invoice.InvoiceStatus.PENDING);
        pending.setTotalAmount(new BigDecimal("1200000"));
        pending.setPaidAmount(BigDecimal.ZERO);
        when(invoiceRepository.findByContractId(eq(1L), any())).thenReturn(new PageImpl<>(List.of(pending)));

        assertThatThrownBy(() -> contractService.cancel(1L, "Khach bo coc"))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("cong no");
        verify(contractRepository, never()).save(any());
    }

    @Test
    @DisplayName("UC67: Cancel is blocked when an invoice was already paid")
    void cancel_blockedByPaidInvoice() {
        Contract contract = baseContract(1L, Contract.ContractStatus.ACTIVE);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));
        Invoice paid = new Invoice();
        paid.setStatus(Invoice.InvoiceStatus.PAID);
        paid.setTotalAmount(new BigDecimal("1200000"));
        paid.setPaidAmount(new BigDecimal("1200000"));
        when(invoiceRepository.findByContractId(eq(1L), any())).thenReturn(new PageImpl<>(List.of(paid)));

        assertThatThrownBy(() -> contractService.cancel(1L, "Thoa thuan lai"))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("Tat toan");
    }

    @Test
    @DisplayName("UC67: Cancel with reason and no debt releases the room")
    void cancel_withReason_releasesRoom() {
        Contract contract = baseContract(1L, Contract.ContractStatus.DRAFT);
        Room room = baseRoom();
        room.setStatus(RoomStatus.DEPOSITED);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));
        when(invoiceRepository.findByContractId(eq(1L), any())).thenReturn(new PageImpl<>(List.of()));
        when(contractRepository.save(any(Contract.class))).thenAnswer(inv -> inv.getArgument(0));
        when(roomRepository.findById(10L)).thenReturn(Optional.of(room));

        ContractResult result = contractService.cancel(1L, " Khach bo coc ");

        assertThat(result.status()).isEqualTo("CANCELED");
        assertThat(contract.getCancelReason()).isEqualTo("Khach bo coc");
        assertThat(room.getStatus()).isEqualTo(RoomStatus.EMPTY);
    }

    @Test
    @DisplayName("UC69: Collect deposit records amount, date and method")
    void collectDeposit_recordsTransaction() {
        Contract contract = baseContract(1L, Contract.ContractStatus.DRAFT);
        Room room = baseRoom();
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));
        when(contractRepository.save(any(Contract.class))).thenAnswer(inv -> inv.getArgument(0));
        when(roomRepository.findById(10L)).thenReturn(Optional.of(room));

        ContractResult result = contractService.collectDeposit(1L, new DepositCollectCommand(
                new BigDecimal("5000000"), LocalDate.now().minusDays(1), "bank_transfer", "Chuyen khoan VCB"));

        ArgumentCaptor<ContractAppendix> captor = ArgumentCaptor.forClass(ContractAppendix.class);
        verify(contractAppendixRepository).save(captor.capture());
        assertThat(captor.getValue().getAppendixType()).isEqualTo("DEPOSIT_COLLECTED");
        assertThat(captor.getValue().getMetadata()).contains("\"paymentMethod\":\"BANK_TRANSFER\"").contains("5000000");
        assertThat(result.depositStatus()).isEqualTo("PAID");
        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(room.getStatus()).isEqualTo(RoomStatus.RENTED);
    }

    @Test
    @DisplayName("UC69: Collect deposit rejects a wrong amount and future date")
    void collectDeposit_validatesInput() {
        Contract contract = baseContract(1L, Contract.ContractStatus.DRAFT);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));

        assertThatThrownBy(() -> contractService.collectDeposit(1L, new DepositCollectCommand(
                new BigDecimal("100"), LocalDate.now(), "CASH", null)))
                .isInstanceOf(BaseException.class);
        assertThatThrownBy(() -> contractService.collectDeposit(1L, new DepositCollectCommand(
                new BigDecimal("5000000"), LocalDate.now().plusDays(2), "CASH", null)))
                .isInstanceOf(BaseException.class);
        verify(contractAppendixRepository, never()).save(any());
    }

    @Test
    @DisplayName("UC65: Resident cannot view another resident's contract")
    void getDetail_residentIsolation() {
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userId.toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_RESIDENT"))));
        Contract contract = baseContract(1L, Contract.ContractStatus.ACTIVE);
        when(contractRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(contract));
        when(contractResidentRepository.findByContractId(1L)).thenReturn(List.of());

        assertThatThrownBy(() -> contractService.getDetail(1L))
                .isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("UC66: Adjustment reason is merged into appendix metadata")
    void mergeReason_buildsJson() {
        assertThat(ContractService.mergeReason(null, "Tang gia"))
                .isEqualTo("{\"reason\":\"Tang gia\"}");
        assertThat(ContractService.mergeReason("{\"newEndDate\":\"2027-01-01\"}", "Gia han \"1 nam\""))
                .isEqualTo("{\"newEndDate\":\"2027-01-01\",\"reason\":\"Gia han \\\"1 nam\\\"\"}");
        assertThat(ContractService.mergeReason("Dieu khoan nuoi thu cung", "Bo sung"))
                .isEqualTo("{\"note\":\"Dieu khoan nuoi thu cung\",\"reason\":\"Bo sung\"}");
    }

    @Test
    @DisplayName("UC68: PDF text is ASCII and VND formatted")
    void pdfHelpers_formatValues() {
        assertThat(ContractService.formatVnd(new BigDecimal("3500000"))).isEqualTo("3.500.000 VND");
        assertThat(ContractService.stripAccents("Hợp đồng Đà Nẵng")).isEqualTo("Hop dong Da Nang");
    }

    private Contract baseContract(Long id, Contract.ContractStatus status) {
        Contract c = new Contract();
        c.setId(id);
        c.setTenantId(tenantId);
        c.setRoomId(10L);
        c.setPrimaryResidentUserId(UUID.randomUUID());
        c.setRentPrice(new BigDecimal("4500000"));
        c.setStartDate(LocalDate.of(2024, 1, 1));
        c.setEndDate(LocalDate.of(2025, 1, 1));
        c.setDepositAmount(new BigDecimal("5000000"));
        c.setDepositStatus(Contract.DepositStatus.UNPAID);
        c.setBillingDate(null);
        c.setStatus(status);
        c.setCreatedBy(userId);
        return c;
    }

    private Room baseRoom() {
        Room room = new Room();
        room.setId(10L);
        room.setMotelId(100L);
        room.setStatus(RoomStatus.EMPTY);
        room.setCurrentResidentsCount(0);
        return room;
    }
}

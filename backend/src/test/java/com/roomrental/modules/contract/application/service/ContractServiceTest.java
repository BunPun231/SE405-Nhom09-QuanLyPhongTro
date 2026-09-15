package com.roomrental.modules.contract.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.contract.application.dto.ContractCreateCommand;
import com.roomrental.modules.contract.application.dto.ContractResult;
import com.roomrental.modules.contract.domain.model.Contract;
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

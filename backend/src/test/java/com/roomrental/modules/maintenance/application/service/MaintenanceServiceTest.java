package com.roomrental.modules.maintenance.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import com.roomrental.modules.device.domain.model.Device;
import com.roomrental.modules.device.domain.model.DeviceStatus;
import com.roomrental.modules.device.domain.repository.DeviceRepository;
import com.roomrental.modules.device.infrastructure.repository.DeviceMovementLogJpaRepository;
import com.roomrental.modules.device.infrastructure.repository.DeviceUsageJpaRepository;
import com.roomrental.modules.finance.application.service.CloudinaryService;
import com.roomrental.modules.maintenance.application.dto.*;
import com.roomrental.modules.maintenance.domain.model.MaintenanceStatus;
import com.roomrental.modules.maintenance.infrastructure.entity.MaintenanceTicketEntity;
import com.roomrental.modules.maintenance.infrastructure.repository.MaintenanceDetailJpaRepository;
import com.roomrental.modules.maintenance.infrastructure.repository.MaintenanceTicketJpaRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("MaintenanceService Unit Tests")
class MaintenanceServiceTest {

    @Mock private MaintenanceTicketJpaRepository ticketRepository;
    @Mock private MaintenanceDetailJpaRepository detailRepository;
    @Mock private RoomRepository roomRepository;
    @Mock private DeviceRepository deviceRepository;
    @Mock private DeviceUsageJpaRepository deviceUsageJpaRepository;
    @Mock private DeviceMovementLogJpaRepository deviceMovementLogJpaRepository;
    @Mock private UserJpaRepository userRepository;
    @Mock private CloudinaryService cloudinaryService;

    @InjectMocks private MaintenanceService maintenanceService;

    private UUID tenantId;
    private UUID currentUserId;

    @BeforeEach
    void setUp() {
        tenantId = UUID.randomUUID();
        currentUserId = UUID.randomUUID();
        TenantContext.setCurrentTenantId(tenantId.toString());
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        currentUserId.toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))));
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("Complete ticket directly from OPEN: deducts inventory and logs movement")
    void completeTicket_fromOpen_success() {
        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setId(10L);
        ticket.setRoomId(101L);
        ticket.setStatus(MaintenanceStatus.OPEN.name());
        ticket.setReportedBy(currentUserId);

        Room room = new Room();
        room.setId(101L);
        room.setMotelId(1L);
        room.setRoomNumber("101");

        Device device = new Device();
        device.setId(5L);
        device.setMotelId(1L);
        device.setName("Bóng đèn Led");
        device.setTotalQuantity(10);
        device.setPurchasePrice(BigDecimal.valueOf(50000));
        device.setStatus(DeviceStatus.IN_STOCK);

        when(ticketRepository.findById(10L)).thenReturn(Optional.of(ticket));
        when(roomRepository.findById(101L)).thenReturn(Optional.of(room));
        when(deviceRepository.findById(5L)).thenReturn(Optional.of(device));
        when(deviceUsageJpaRepository.findByDeviceId(5L)).thenReturn(List.of());
        when(ticketRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CompleteTicketCommand command = new CompleteTicketCommand(
                List.of(new UsedDeviceItem(5L, 2, null)), "Đã thay 2 bóng đèn", null);

        MaintenanceTicketResult result = maintenanceService.completeTicket(10L, command);

        assertThat(result.status()).isEqualTo("COMPLETED");
        assertThat(device.getTotalQuantity()).isEqualTo(8);
        verify(deviceRepository).save(device);
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "MAINTENANCE_USE".equals(log.getAction()) && log.getQuantity() == 2 && Long.valueOf(101L).equals(log.getToRoomId())));
        verify(detailRepository).save(argThat(detail ->
                Long.valueOf(5L).equals(detail.getDeviceId()) && detail.getQuantityUsed() == 2));
    }

    @Test
    @DisplayName("Complete ticket when already COMPLETED: throws BaseException badRequest")
    void completeTicket_alreadyCompleted_throwsBadRequest() {
        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setId(10L);
        ticket.setStatus(MaintenanceStatus.COMPLETED.name());

        when(ticketRepository.findById(10L)).thenReturn(Optional.of(ticket));

        CompleteTicketCommand command = new CompleteTicketCommand(List.of(), "Lại hoàn thành", null);

        assertThatThrownBy(() -> maintenanceService.completeTicket(10L, command))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("Phiếu bảo trì đã hoàn thành không thể mở lại");
    }

    @Test
    @DisplayName("Assign technician when ticket already COMPLETED: throws BaseException badRequest")
    void assignTicket_alreadyCompleted_throwsBadRequest() {
        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setId(10L);
        ticket.setStatus(MaintenanceStatus.COMPLETED.name());

        when(ticketRepository.findById(10L)).thenReturn(Optional.of(ticket));

        assertThatThrownBy(() -> maintenanceService.assignTicket(10L, new AssignTicketCommand(UUID.randomUUID())))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("Phiếu bảo trì đã hoàn thành không thể mở lại");
    }

    @Test
    @DisplayName("Complete ticket with device belonging to another motel: throws BaseException badRequest")
    void completeTicket_deviceWrongMotel_throwsBadRequest() {
        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setId(10L);
        ticket.setRoomId(101L);
        ticket.setStatus(MaintenanceStatus.PROCESSING.name());

        Room room = new Room();
        room.setId(101L);
        room.setMotelId(1L);

        Device device = new Device();
        device.setId(5L);
        device.setMotelId(2L); // Different motel!

        when(ticketRepository.findById(10L)).thenReturn(Optional.of(ticket));
        when(roomRepository.findById(101L)).thenReturn(Optional.of(room));
        when(deviceRepository.findById(5L)).thenReturn(Optional.of(device));

        CompleteTicketCommand command = new CompleteTicketCommand(
                List.of(new UsedDeviceItem(5L, 1, null)), "Gán thiết bị nhà trọ khác", null);

        assertThatThrownBy(() -> maintenanceService.completeTicket(10L, command))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("Thiết bị không thuộc nhà trọ của phòng này");
    }

    @Test
    @DisplayName("Complete ticket with insufficient inventory: throws BaseException badRequest")
    void completeTicket_insufficientStock_throwsBadRequest() {
        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setId(10L);
        ticket.setRoomId(101L);
        ticket.setStatus(MaintenanceStatus.PROCESSING.name());

        Room room = new Room();
        room.setId(101L);
        room.setMotelId(1L);

        Device device = new Device();
        device.setId(5L);
        device.setMotelId(1L);
        device.setTotalQuantity(2);

        when(ticketRepository.findById(10L)).thenReturn(Optional.of(ticket));
        when(roomRepository.findById(101L)).thenReturn(Optional.of(room));
        when(deviceRepository.findById(5L)).thenReturn(Optional.of(device));
        when(deviceUsageJpaRepository.findByDeviceId(5L)).thenReturn(List.of());

        CompleteTicketCommand command = new CompleteTicketCommand(
                List.of(new UsedDeviceItem(5L, 5, null)), "Dùng 5 chiếc trong khi chỉ còn 2", null);

        assertThatThrownBy(() -> maintenanceService.completeTicket(10L, command))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("vượt quá số lượng khả dụng trong kho");
    }

    @Test
    @DisplayName("Complete ticket without replacement devices: saves detail with null deviceId")
    void completeTicket_withoutDevices_success() {
        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setId(10L);
        ticket.setRoomId(101L);
        ticket.setStatus(MaintenanceStatus.PROCESSING.name());
        ticket.setReportedBy(currentUserId);

        Room room = new Room();
        room.setId(101L);
        room.setMotelId(1L);
        room.setRoomNumber("101");

        when(ticketRepository.findById(10L)).thenReturn(Optional.of(ticket));
        when(roomRepository.findById(101L)).thenReturn(Optional.of(room));
        when(ticketRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CompleteTicketCommand command = new CompleteTicketCommand(
                List.of(), "Đã sửa xong đường điện, không cần thay mới", null);

        MaintenanceTicketResult result = maintenanceService.completeTicket(10L, command);

        assertThat(result.status()).isEqualTo("COMPLETED");
        verify(detailRepository).save(argThat(detail -> detail.getDeviceId() == null && detail.getQuantityUsed() == 0));
        verify(deviceRepository, never()).save(any());
        verify(deviceMovementLogJpaRepository, never()).save(any());
    }
}

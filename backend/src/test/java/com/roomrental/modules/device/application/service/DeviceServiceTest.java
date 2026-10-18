package com.roomrental.modules.device.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.device.application.dto.DeviceCreateCommand;
import com.roomrental.modules.device.application.dto.DeviceResult;
import com.roomrental.modules.device.application.dto.DeviceUpdateCommand;
import com.roomrental.modules.device.domain.model.Device;
import com.roomrental.modules.device.domain.model.DeviceStatus;
import com.roomrental.modules.device.domain.repository.DeviceRepository;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
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
@DisplayName("DeviceService Unit Tests")
class DeviceServiceTest {

    @Mock private DeviceRepository deviceRepository;
    @Mock private com.roomrental.modules.device.infrastructure.repository.DeviceUsageJpaRepository deviceUsageJpaRepository;
    @Mock private com.roomrental.modules.device.infrastructure.repository.DeviceMovementLogJpaRepository deviceMovementLogJpaRepository;
    @Mock private MotelRepository motelRepository;
    @Mock private com.roomrental.modules.room.domain.repository.RoomRepository roomRepository;
    @Mock private org.springframework.context.ApplicationEventPublisher eventPublisher;
    @InjectMocks private DeviceService deviceService;

    private UUID tenantId;
    private Motel motel;

    @BeforeEach
    void setUp() {
        tenantId = UUID.randomUUID();
        TenantContext.setCurrentTenantId(tenantId.toString());
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(
                        UUID.randomUUID().toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))));
        motel = new Motel();
        motel.setId(1L);
        motel.setTenantId(tenantId);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("UC40: Create device")
    void create_success() {
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> {
            Device d = inv.getArgument(0);
            d.setId(1L);
            return d;
        });

        DeviceResult result = deviceService.create(1L,
                new DeviceCreateCommand("AC", "Daikin", BigDecimal.valueOf(8000000), LocalDate.now(), 5));

        assertThat(result.name()).isEqualTo("AC");
        assertThat(result.status()).isEqualTo("IN_STOCK");
        assertThat(result.totalQuantity()).isEqualTo(5);
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "IMPORT".equals(log.getAction()) && log.getQuantity() == 5));
    }

    @Test
    @DisplayName("UC44: Update device general info (totalQuantity and status are locked)")
    void update_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(5);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceResult result = deviceService.update(1L, 1L,
                new DeviceUpdateCommand("AC Updated", "Daikin", BigDecimal.valueOf(8500000), LocalDate.now()));

        assertThat(result.name()).isEqualTo("AC Updated");
        assertThat(result.totalQuantity()).isEqualTo(5);
    }

    @Test
    @DisplayName("Stock Import: Increment total quantity and log")
    void importStock_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(5);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceResult result = deviceService.importStock(1L, 1L,
                new com.roomrental.modules.device.application.dto.DeviceImportCommand(3, "Nhập thêm 3 chiếc"));

        assertThat(result.totalQuantity()).isEqualTo(8);
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "IMPORT".equals(log.getAction()) && log.getQuantity() == 3));
    }

    @Test
    @DisplayName("Stock Dispose: Decrement total quantity and log")
    void disposeStock_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(5);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenAnswer(inv -> inv.getArgument(0));

        DeviceResult result = deviceService.disposeStock(1L, 1L,
                new com.roomrental.modules.device.application.dto.DeviceDisposeCommand(2, "Hỏng linh kiện không sửa được"));

        assertThat(result.totalQuantity()).isEqualTo(3);
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "DISPOSE".equals(log.getAction()) && log.getQuantity() == 2));
    }

    @Test
    @DisplayName("Stock Dispose: Exceed available quantity throws error")
    void disposeStock_exceedAvailable_throwsError() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(3);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> deviceService.disposeStock(1L, 1L,
                new com.roomrental.modules.device.application.dto.DeviceDisposeCommand(5, "Quá số lượng tồn")))
                .isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("UC45: Soft delete - success when not in use")
    void delete_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(deviceRepository.save(any(Device.class))).thenReturn(device);

        deviceService.delete(1L, 1L);
        verify(deviceRepository).save(argThat(Device::isDeleted));
    }

    @Test
    @DisplayName("UC47: Full recall deletes usage and logs movement")
    void recall_fullRecall_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(5);

        com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity usage =
                new com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity();
        usage.setId(10L);
        usage.setDeviceId(1L);
        usage.setRoomId(101L);
        usage.setAssignedQuantity(3);

        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(deviceUsageJpaRepository.findByDeviceIdAndRoomId(1L, 101L)).thenReturn(Optional.of(usage));
        when(deviceUsageJpaRepository.findByDeviceId(1L)).thenReturn(List.of());

        deviceService.recallDeviceFromRoom(1L, 1L, 101L,
                new com.roomrental.modules.device.application.dto.DeviceRecallCommand(3, "Thu hồi toàn bộ"));

        verify(deviceUsageJpaRepository).delete(usage);
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "RECALL".equals(log.getAction()) && log.getQuantity() == 3 && Long.valueOf(101L).equals(log.getFromRoomId())));
    }

    @Test
    @DisplayName("UC47: Partial recall decrements assigned quantity and logs movement")
    void recall_partialRecall_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(5);

        com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity usage =
                new com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity();
        usage.setId(10L);
        usage.setDeviceId(1L);
        usage.setRoomId(101L);
        usage.setAssignedQuantity(3);

        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(deviceUsageJpaRepository.findByDeviceIdAndRoomId(1L, 101L)).thenReturn(Optional.of(usage));
        when(deviceUsageJpaRepository.findByDeviceId(1L)).thenReturn(List.of(usage));

        deviceService.recallDeviceFromRoom(1L, 1L, 101L,
                new com.roomrental.modules.device.application.dto.DeviceRecallCommand(1, "Thu hồi 1 chiếc"));

        verify(deviceUsageJpaRepository, never()).delete(any());
        verify(deviceUsageJpaRepository).save(argThat(u -> u.getAssignedQuantity() == 2));
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "RECALL".equals(log.getAction()) && log.getQuantity() == 1 && Long.valueOf(101L).equals(log.getFromRoomId())));
    }

    @Test
    @DisplayName("UC46: Assign device to room with optional condition defaults to GOOD")
    void assign_defaultCondition_success() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setName("Tủ lạnh");
        device.setStatus(DeviceStatus.IN_STOCK);
        device.setTotalQuantity(5);

        com.roomrental.modules.room.domain.model.Room room = new com.roomrental.modules.room.domain.model.Room();
        room.setId(101L);
        room.setMotelId(1L);

        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));
        when(roomRepository.findByIdAndMotelId(101L, 1L)).thenReturn(Optional.of(room));
        when(deviceUsageJpaRepository.findByDeviceId(1L)).thenReturn(List.of());
        when(deviceUsageJpaRepository.findByDeviceIdAndRoomId(1L, 101L)).thenReturn(Optional.empty());
        when(deviceUsageJpaRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        com.roomrental.modules.device.application.dto.DeviceUsageResult result = deviceService.assignDeviceToRoom(
                1L, 1L, new com.roomrental.modules.device.application.dto.DeviceAssignCommand(101L, 2, null, "Gán 2 cái"));

        assertThat(result.assignedQuantity()).isEqualTo(2);
        assertThat(result.condition()).isEqualTo("GOOD");
        verify(deviceMovementLogJpaRepository).save(argThat(log ->
                "ASSIGN".equals(log.getAction()) && log.getQuantity() == 2 && Long.valueOf(101L).equals(log.getToRoomId())));
    }
}

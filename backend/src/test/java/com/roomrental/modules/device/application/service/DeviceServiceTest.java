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
    @Mock private MotelRepository motelRepository;
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
                new DeviceCreateCommand("AC", "Daikin", BigDecimal.valueOf(8000000), LocalDate.now()));

        assertThat(result.name()).isEqualTo("AC");
        assertThat(result.status()).isEqualTo("IN_STOCK");
    }

    @Test
    @DisplayName("UC44: Update - invalid status")
    void update_invalidStatus() {
        Device device = new Device();
        device.setId(1L);
        device.setMotelId(1L);
        device.setStatus(DeviceStatus.IN_STOCK);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(deviceRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(device));

        assertThatThrownBy(() -> deviceService.update(1L, 1L,
                new DeviceUpdateCommand(null, null, null, null, "INVALID")))
                .isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("UC45: Soft delete")
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
}

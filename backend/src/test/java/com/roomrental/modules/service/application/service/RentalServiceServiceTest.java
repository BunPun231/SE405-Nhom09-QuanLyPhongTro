package com.roomrental.modules.service.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.service.application.dto.ServiceCreateCommand;
import com.roomrental.modules.service.application.dto.ServiceResult;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("RentalServiceService Unit Tests")
class RentalServiceServiceTest {

    @Mock private RentalServiceRepository serviceRepository;
    @Mock private ServicePricingRepository servicePricingRepository;
    @Mock private MotelRepository motelRepository;
    @Mock private ApplicationEventPublisher eventPublisher;
    @InjectMocks private RentalServiceService serviceService;

    private UUID tenantId;

    @BeforeEach
    void setUp() {
        tenantId = UUID.randomUUID();
        TenantContext.setCurrentTenantId(tenantId.toString());
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(UUID.randomUUID().toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))));
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("UC32: Create service successfully")
    void create_success() {
        Motel motel = new Motel();
        motel.setId(1L);
        motel.setTenantId(tenantId);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(serviceRepository.existsByMotelIdAndName(1L, "Điện")).thenReturn(false);
        doNothing().when(servicePricingRepository).closeCurrentPricing(anyLong(), any());
        when(servicePricingRepository.findCurrentByServiceId(anyLong(), any())).thenReturn(Optional.empty());
        when(serviceRepository.save(any(RentalService.class))).thenAnswer(inv -> {
            RentalService s = inv.getArgument(0);
            s.setId(1L);
            return s;
        });

        ServiceResult result = serviceService.create(1L,
            new ServiceCreateCommand("Điện", "PER_INDEX", "kWh", true, null, null));

        assertThat(result.name()).isEqualTo("Điện");
        assertThat(result.chargeType()).isEqualTo("PER_INDEX");
        assertThat(result.mandatory()).isTrue();
    }

    @Test
    @DisplayName("UC32: Fail - duplicate name")
    void create_duplicateName() {
        Motel motel = new Motel();
        motel.setId(1L);
        motel.setTenantId(tenantId);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(serviceRepository.existsByMotelIdAndName(1L, "Điện")).thenReturn(true);

        assertThatThrownBy(() -> serviceService.create(1L,
            new ServiceCreateCommand("Điện", "FIXED", null, false, null, null)))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    @DisplayName("UC32: Fail - invalid charge type")
    void create_invalidChargeType() {
        Motel motel = new Motel();
        motel.setId(1L);
        motel.setTenantId(tenantId);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(serviceRepository.existsByMotelIdAndName(anyLong(), anyString())).thenReturn(false);

        assertThatThrownBy(() -> serviceService.create(1L,
            new ServiceCreateCommand("Test", "INVALID_TYPE", null, false, null, null)))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("Invalid charge type");
    }
}

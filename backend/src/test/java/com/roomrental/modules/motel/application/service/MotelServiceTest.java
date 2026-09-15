package com.roomrental.modules.motel.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.motel.application.dto.MotelResult;
import com.roomrental.modules.motel.application.dto.MotelUpsertCommand;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("MotelService Unit Tests")
class MotelServiceTest {

    @Mock private MotelRepository motelRepository;
    @Mock private ApplicationEventPublisher eventPublisher;
    @InjectMocks private MotelService motelService;

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
    @DisplayName("UC20: Create motel successfully")
    void create_success() {
        when(motelRepository.save(any(Motel.class))).thenAnswer(inv -> {
            Motel m = inv.getArgument(0);
            m.setId(1L);
            return m;
        });

        MotelResult result = motelService.create(new MotelUpsertCommand(
            "Nhà trọ A",
            "123 Street",
            3,
            "desc",
            25,
            null,
            null
        ));

        assertThat(result.id()).isEqualTo(1L);
        assertThat(result.name()).isEqualTo("Nhà trọ A");
        assertThat(result.address()).isEqualTo("123 Street");
    }

    @Test
    @DisplayName("UC21: List motels with pagination")
    void list_success() {
        Motel motel = createMotel(1L, "Motel A");
        when(motelRepository.findByTenantId(eq(tenantId), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(motel)));

        PageResponse<MotelResult> result = motelService.list(PageRequest.of(0, 20));

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getTotalElements()).isEqualTo(1);
    }

    @Test
    @DisplayName("UC22: Get motel detail - not found throws exception")
    void get_notFound() {
        when(motelRepository.findByIdAndTenantId(99L, tenantId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> motelService.get(99L))
                .isInstanceOf(BaseException.class);
    }

    @Test
    @DisplayName("UC25: Delete motel - soft delete")
    void delete_success() {
        Motel motel = createMotel(1L, "To Delete");
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(motelRepository.save(any(Motel.class))).thenReturn(motel);

        motelService.delete(1L);

        verify(motelRepository).save(argThat(m -> m.isDeleted()));
    }

    private Motel createMotel(Long id, String name) {
        Motel m = new Motel();
        m.setId(id);
        m.setTenantId(tenantId);
        m.setName(name);
        m.setAddress("Address");
        m.setTotalFloors(2);
        return m;
    }
}

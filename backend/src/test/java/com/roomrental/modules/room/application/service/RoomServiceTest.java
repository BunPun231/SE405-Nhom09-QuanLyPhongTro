package com.roomrental.modules.room.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.room.application.dto.RoomCreateCommand;
import com.roomrental.modules.room.application.dto.RoomResult;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("RoomService Unit Tests")
class RoomServiceTest {

    @Mock private RoomRepository roomRepository;
    @Mock private MotelRepository motelRepository;
    @Mock private ApplicationEventPublisher eventPublisher;
    @Mock private com.roomrental.common.util.HashidsCodec hashidsCodec;
    @InjectMocks private RoomService roomService;

    private UUID tenantId;
    private Motel motel;

    @BeforeEach
    void setUp() {
        tenantId = UUID.randomUUID();
        TenantContext.setCurrentTenantId(tenantId.toString());
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(UUID.randomUUID().toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))));

        motel = new Motel();
        motel.setId(1L);
        motel.setTenantId(tenantId);
        motel.setTotalFloors(5);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("UC26: Create room successfully")
    void create_success() {
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(roomRepository.existsByMotelIdAndRoomNumber(1L, "101")).thenReturn(false);
        when(roomRepository.save(any(Room.class))).thenAnswer(inv -> {
            Room r = inv.getArgument(0);
            r.setId(1L);
            return r;
        });

        RoomResult result = roomService.create(1L,
                new RoomCreateCommand("101", 1, BigDecimal.valueOf(25), BigDecimal.valueOf(3000000), "Nice room"));

        assertThat(result.roomNumber()).isEqualTo("101");
        assertThat(result.status()).isEqualTo("EMPTY");
    }

    @Test
    @DisplayName("UC26+: Bulk create rooms successfully")
    void bulkCreate_success() {
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(roomRepository.existsByMotelIdAndRoomNumber(eq(1L), anyString())).thenReturn(false);
        when(roomRepository.save(any(Room.class))).thenAnswer(inv -> {
            Room r = inv.getArgument(0);
            r.setId(r.getRoomNumber().equals("101") ? 1L : 2L);
            return r;
        });

        var results = roomService.createBulk(1L, List.of(
                new RoomCreateCommand("101", 1, BigDecimal.valueOf(25), BigDecimal.valueOf(3000000), "Nice room"),
                new RoomCreateCommand("102", 1, BigDecimal.valueOf(26), BigDecimal.valueOf(3200000), "Nice room 2")
        ));

        assertThat(results).hasSize(2);
        assertThat(results.get(0).roomNumber()).isEqualTo("101");
        assertThat(results.get(1).roomNumber()).isEqualTo("102");
    }

    @Test
    @DisplayName("UC26: Fail create - duplicate room number")
    void create_duplicateRoomNumber() {
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(roomRepository.existsByMotelIdAndRoomNumber(1L, "101")).thenReturn(true);

        assertThatThrownBy(() -> roomService.create(1L,
                new RoomCreateCommand("101", 1, null, BigDecimal.valueOf(3000000), null)))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    @DisplayName("UC26: Fail create - floor exceeds motel floors")
    void create_floorExceeds() {
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(roomRepository.existsByMotelIdAndRoomNumber(1L, "601")).thenReturn(false);

        assertThatThrownBy(() -> roomService.create(1L,
                new RoomCreateCommand("601", 6, null, BigDecimal.valueOf(3000000), null)))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("exceeds");
    }

    @Test
    @DisplayName("UC31: Delete room - only when EMPTY")
    void delete_onlyEmpty() {
        Room room = new Room();
        room.setId(1L);
        room.setMotelId(1L);
        room.setStatus(RoomStatus.RENTED);
        when(motelRepository.findByIdAndTenantId(1L, tenantId)).thenReturn(Optional.of(motel));
        when(roomRepository.findByIdAndMotelId(1L, 1L)).thenReturn(Optional.of(room));

        assertThatThrownBy(() -> roomService.delete(1L, 1L))
                .isInstanceOf(BaseException.class)
                .hasMessageContaining("EMPTY");
    }
}

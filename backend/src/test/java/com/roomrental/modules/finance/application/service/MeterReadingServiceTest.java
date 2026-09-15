package com.roomrental.modules.finance.application.service;

import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.finance.application.dto.MeterReadingSubmitCommand;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.port.OcrPort;
import com.roomrental.modules.finance.domain.port.OcrResult;
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
@DisplayName("MeterReadingService Unit Tests")
class MeterReadingServiceTest {

    @Mock private MeterReadingRepository meterReadingRepository;
    @Mock private ServiceUsageRepository serviceUsageRepository;
    @Mock private OcrPort ocrPort;
    @Mock private ApplicationEventPublisher eventPublisher;
    @Mock private CloudinaryService cloudinaryService;
    @Mock private RoomRepository roomRepository;
    @Mock private RentalServiceRepository rentalServiceRepository;
    @InjectMocks private MeterReadingService meterReadingService;

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
    @DisplayName("Submit reading uses service usage start index when there is no prior reading")
    void submit_usesServiceUsageStartIndex() {
        Room room = new Room();
        room.setId(10L);
        room.setStatus(RoomStatus.RENTED);

        ServiceUsage usage = new ServiceUsage();
        usage.setId(55L);
        usage.setStartIndex(new BigDecimal("123"));

        when(roomRepository.findById(10L)).thenReturn(Optional.of(room));
        when(serviceUsageRepository.findActiveByRoomIdAndServiceId(10L, 88L)).thenReturn(Optional.of(usage));
        when(meterReadingRepository.existsByServiceUsageIdAndBillingMonthAndStatus(55L, LocalDate.of(2026, 6, 1), "APPROVED"))
                .thenReturn(false);
        when(meterReadingRepository.findLatestApprovedByServiceUsageId(55L)).thenReturn(Optional.empty());
        when(serviceUsageRepository.findById(55L)).thenReturn(Optional.of(usage));
        when(meterReadingRepository.save(any(MeterReading.class))).thenAnswer(inv -> {
            MeterReading reading = inv.getArgument(0);
            reading.setId(1L);
            return reading;
        });

        MeterReadingSubmitCommand command = new MeterReadingSubmitCommand(
                10L, 88L, LocalDate.of(2026, 6, 15), new BigDecimal("150"), null);

        var result = meterReadingService.submit(command);

        ArgumentCaptor<MeterReading> captor = ArgumentCaptor.forClass(MeterReading.class);
        verify(meterReadingRepository).save(captor.capture());
        assertThat(captor.getValue().getOldReading()).isEqualByComparingTo("123");
        assertThat(result.oldReading()).isEqualByComparingTo("123");
    }
}
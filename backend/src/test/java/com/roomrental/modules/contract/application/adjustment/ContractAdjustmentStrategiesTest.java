package com.roomrental.modules.contract.application.adjustment;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.TenantContext;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.model.ContractAppendix;
import com.roomrental.modules.contract.domain.repository.ContractAppendixRepository;
import com.roomrental.modules.invoice.domain.repository.InvoiceReadRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Contract Adjustment Strategies")
class ContractAdjustmentStrategiesTest {

    static {
        System.setProperty("net.bytebuddy.experimental", "true");
    }

    @Mock private ContractAppendixRepository appendixRepository;
    @Mock private InvoiceReadRepository invoiceReadRepository;

    @InjectMocks private PriceChangeStrategy priceChangeStrategy;
    @InjectMocks private RenewStrategy renewStrategy;
    @InjectMocks private MoveOutNoticeStrategy moveOutNoticeStrategy;
    @InjectMocks private ManualAppendixStrategy manualAppendixStrategy;

    private Contract contract;


    private UUID userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        TenantContext.setCurrentTenantId(UUID.randomUUID().toString());
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userId.toString(), null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))));
        contract = new Contract();
        contract.setId(200L);
        contract.setTenantId(UUID.fromString(TenantContext.getCurrentTenantId()));
        contract.setEndDate(LocalDate.of(2025,1,1));
        contract.setStatus(Contract.ContractStatus.ACTIVE);
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
        SecurityContextHolder.clearContext();
    }

    @Test
    void priceChange_savesAppendix_whenNoPaidInvoice() {
        when(invoiceReadRepository.existsPaidInvoiceCovering(contract.getId(), LocalDate.now().plusDays(1))).thenReturn(false);
        when(appendixRepository.save(any(ContractAppendix.class))).thenAnswer(inv -> {
            ContractAppendix a = inv.getArgument(0);
            a.setId(1L);
            return a;
        });
        ContractAdjustmentRequest req = new ContractAdjustmentRequest(
                "PRICE_CHANGE",
            LocalDate.now().plusDays(1),
            new BigDecimal("4800000"),
            null,
            null,
            null,
            false,
            null
        );
        Long id = priceChangeStrategy.process(contract, req);
        assertThat(id).isEqualTo(1L);
        verify(appendixRepository).save(any(ContractAppendix.class));
    }

    @Test
    void priceChange_throws_whenOverlapPaidInvoice() {
        when(invoiceReadRepository.existsPaidInvoiceCovering(contract.getId(), LocalDate.now().plusDays(1))).thenReturn(true);
        ContractAdjustmentRequest req = new ContractAdjustmentRequest(
                "PRICE_CHANGE",
            LocalDate.now().plusDays(1),
            new BigDecimal("4800000"),
            null,
            null,
            null,
            false,
            null
        );
        assertThatThrownBy(() -> priceChangeStrategy.process(contract, req)).isInstanceOf(BaseException.class);
    }

    @Test
    void renew_createsAppendix_and_updatesContractEndDate() {
        when(appendixRepository.save(any(ContractAppendix.class))).thenAnswer(inv -> {
            ContractAppendix a = inv.getArgument(0);
            a.setId(2L);
            return a;
        });
        LocalDate newEnd = LocalDate.of(2026,1,1);
        ContractAdjustmentRequest req = new ContractAdjustmentRequest(
                "RENEW",
            null,
            null,
            newEnd,
            null,
            null,
            false,
            null
        );
        Long id = renewStrategy.process(contract, req);
        assertThat(id).isEqualTo(2L);
        verify(appendixRepository).save(any(ContractAppendix.class));
        assertThat(contract.getEndDate()).isEqualTo(newEnd);
    }

    @Test
    void moveOutNotice_updatesIntendedMoveOutDate() {
        LocalDate moveOut = LocalDate.now().plusDays(10);
        ContractAdjustmentRequest req = new ContractAdjustmentRequest(
                "MOVE_OUT_NOTICE",
            null,
            null,
            null,
            moveOut,
            null,
            false,
            null
        );
        Long id = moveOutNoticeStrategy.process(contract, req);
        assertThat(id).isNull();
        assertThat(contract.getIntendedMoveOutDate()).isEqualTo(moveOut);
    }

    @Test
    void manualAppendix_savesMetadata() {
        when(appendixRepository.save(any(ContractAppendix.class))).thenAnswer(inv -> {
            ContractAppendix a = inv.getArgument(0);
            a.setId(3L);
            return a;
        });
        ContractAdjustmentRequest req = new ContractAdjustmentRequest(
                "MANUAL_CLAUSE",
            LocalDate.now().plusDays(2),
            null,
            null,
            null,
            "{\"text\":\"sample clause\"}",
            false,
            null
        );
        Long id = manualAppendixStrategy.process(contract, req);
        assertThat(id).isEqualTo(3L);
        verify(appendixRepository).save(any(ContractAppendix.class));
    }

    @Test
    void manualAppendix_throws_whenMetadataBlank() {
        ContractAdjustmentRequest req = new ContractAdjustmentRequest(
                "MANUAL_CLAUSE",
            LocalDate.now().plusDays(2),
            null,
            null,
            null,
            " ",
            false,
            null
        );
        assertThatThrownBy(() -> manualAppendixStrategy.process(contract, req)).isInstanceOf(BaseException.class);
    }
}

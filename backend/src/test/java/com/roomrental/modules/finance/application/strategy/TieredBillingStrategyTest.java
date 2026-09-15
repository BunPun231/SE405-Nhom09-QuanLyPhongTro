package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("TieredBillingStrategy Unit Tests")
class TieredBillingStrategyTest {

    @Test
    @DisplayName("Calculates tiers in sorted order and skips invalid ranges")
    void calculate_sortsAndSkipsInvalidTiers() {
        TieredBillingStrategy strategy = new TieredBillingStrategy();
        BillingContext context = new BillingContext(
                1L,
                "Nước",
                "PER_INDEX",
                new BigDecimal("0"),
                new BigDecimal("65"),
                null,
                1,
                BigDecimal.ZERO,
                List.of(
                        new BillingContext.PricingTier(new BigDecimal("50"), new BigDecimal("100"), new BigDecimal("5000")),
                        new BillingContext.PricingTier(new BigDecimal("0"), new BigDecimal("50"), new BigDecimal("3000")),
                        new BillingContext.PricingTier(new BigDecimal("100"), new BigDecimal("100"), new BigDecimal("9999"))
                )
        );

        List<InvoiceDetail> details = strategy.calculate(context);

        assertThat(details).hasSize(2);
        assertThat(details.get(0).getLineTotal()).isEqualByComparingTo("150000");
        assertThat(details.get(1).getLineTotal()).isEqualByComparingTo("75000");
    }
}
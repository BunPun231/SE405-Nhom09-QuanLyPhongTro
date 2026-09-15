package com.roomrental.modules.finance.application.strategy;

import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class BillingStrategyFactory {
    
    private final List<BillingStrategy> strategies;

    public BillingStrategyFactory(List<BillingStrategy> strategies) {
        this.strategies = strategies;
    }

    public BillingStrategy getStrategy(String chargeType, boolean hasTiers) {
        return strategies.stream()
            .filter(s -> s.supports(chargeType, hasTiers))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException(
                "No billing strategy found for chargeType=" + chargeType + ", hasTiers=" + hasTiers));
    }
}

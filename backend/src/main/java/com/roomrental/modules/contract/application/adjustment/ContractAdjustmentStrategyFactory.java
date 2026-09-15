package com.roomrental.modules.contract.application.adjustment;

import com.roomrental.common.exception.BaseException;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentType;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class ContractAdjustmentStrategyFactory {
    private final Map<ContractAdjustmentType, ContractAdjustmentStrategy> strategies = new EnumMap<>(ContractAdjustmentType.class);

    public ContractAdjustmentStrategyFactory(List<ContractAdjustmentStrategy> strategyList) {
        for (ContractAdjustmentStrategy strategy : strategyList) {
            strategies.put(strategy.getType(), strategy);
        }
    }

    public ContractAdjustmentStrategy getStrategy(ContractAdjustmentType type) {
        ContractAdjustmentStrategy strategy = strategies.get(type);
        if (strategy == null) {
            throw BaseException.badRequest("type: unsupported adjustment type");
        }
        return strategy;
    }
}

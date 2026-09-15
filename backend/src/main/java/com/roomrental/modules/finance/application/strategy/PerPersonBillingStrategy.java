package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
public class PerPersonBillingStrategy implements BillingStrategy {

    @Override
    public List<InvoiceDetail> calculate(BillingContext context) {
        int residents = context.activeResidents() != null ? context.activeResidents() : 1;
        BigDecimal quantity = BigDecimal.valueOf(residents);
        BigDecimal basePrice = context.basePrice() != null ? context.basePrice() : BigDecimal.ZERO;
        
        String description = String.format("%s (%d người)", context.serviceName(), residents);
        
        return List.of(new InvoiceDetail(
            description,
            quantity,
            basePrice,
            context.serviceId()
        ));
    }

    @Override
    public boolean supports(String chargeType, boolean hasTiers) {
        return "PER_PERSON".equals(chargeType);
    }
}

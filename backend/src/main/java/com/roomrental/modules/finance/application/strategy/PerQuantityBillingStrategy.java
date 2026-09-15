package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
public class PerQuantityBillingStrategy implements BillingStrategy {

    @Override
    public List<InvoiceDetail> calculate(BillingContext context) {
        BigDecimal quantity = context.quantity() != null ? context.quantity() : BigDecimal.ZERO;
        BigDecimal basePrice = context.basePrice() != null ? context.basePrice() : BigDecimal.ZERO;
        
        return List.of(new InvoiceDetail(
            context.serviceName(),
            quantity,
            basePrice,
            context.serviceId()
        ));
    }

    @Override
    public boolean supports(String chargeType, boolean hasTiers) {
        return "PER_QUANTITY".equals(chargeType);
    }
}

package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
public class FixedBillingStrategy implements BillingStrategy {

    @Override
    public List<InvoiceDetail> calculate(BillingContext context) {
        BigDecimal basePrice = context.basePrice() != null ? context.basePrice() : BigDecimal.ZERO;
        return List.of(new InvoiceDetail(
            context.serviceName(),
            BigDecimal.ONE,
            basePrice,
            context.serviceId()
        ));
    }

    @Override
    public boolean supports(String chargeType, boolean hasTiers) {
        return "FIXED".equals(chargeType);
    }
}

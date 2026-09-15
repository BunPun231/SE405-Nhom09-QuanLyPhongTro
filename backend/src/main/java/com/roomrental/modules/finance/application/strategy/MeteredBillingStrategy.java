package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
public class MeteredBillingStrategy implements BillingStrategy {

    @Override
    public List<InvoiceDetail> calculate(BillingContext context) {
        BigDecimal oldReading = context.oldReading() != null ? context.oldReading() : BigDecimal.ZERO;
        BigDecimal newReading = context.newReading() != null ? context.newReading() : BigDecimal.ZERO;
        BigDecimal consumption = newReading.subtract(oldReading).max(BigDecimal.ZERO);
        BigDecimal basePrice = context.basePrice() != null ? context.basePrice() : BigDecimal.ZERO;
        
        String description = String.format("%s (CS cũ: %s, CS mới: %s)", 
            context.serviceName(), oldReading.toPlainString(), newReading.toPlainString());
            
        return List.of(new InvoiceDetail(
            description,
            consumption,
            basePrice,
            context.serviceId()
        ));
    }

    @Override
    public boolean supports(String chargeType, boolean hasTiers) {
        return "METERED".equals(chargeType) || ("PER_INDEX".equals(chargeType) && !hasTiers);
    }
}

package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Component
public class TieredBillingStrategy implements BillingStrategy {

    @Override
    public List<InvoiceDetail> calculate(BillingContext context) {
        BigDecimal oldReading = context.oldReading() != null ? context.oldReading() : BigDecimal.ZERO;
        BigDecimal newReading = context.newReading() != null ? context.newReading() : BigDecimal.ZERO;
        BigDecimal consumption = newReading.subtract(oldReading).max(BigDecimal.ZERO);
        
        List<InvoiceDetail> details = new ArrayList<>();
        BigDecimal remainingConsumption = consumption;
        
        List<BillingContext.PricingTier> tiers = context.pricingTiers();
        if (tiers == null || tiers.isEmpty()) {
            return details;
        }

        tiers = tiers.stream()
                .filter(tier -> tier != null && tier.tierStart() != null && tier.pricePerUnit() != null)
                .sorted(java.util.Comparator.comparing(BillingContext.PricingTier::tierStart))
                .toList();

        for (int i = 0; i < tiers.size(); i++) {
            if (remainingConsumption.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }

            BillingContext.PricingTier tier = tiers.get(i);
            BigDecimal tierStart = tier.tierStart();
            BigDecimal tierEnd = tier.tierEnd();
            if (tierEnd != null && tierEnd.compareTo(tierStart) <= 0) {
                continue;
            }
            
            BigDecimal tierCapacity;
            if (tierEnd != null) {
                tierCapacity = tierEnd.subtract(tierStart);
            } else {
                tierCapacity = remainingConsumption; // Last tier has no upper limit
            }

            BigDecimal consumptionInTier = remainingConsumption.min(tierCapacity);
            
            if (consumptionInTier.compareTo(BigDecimal.ZERO) > 0) {
                String description = String.format("%s (Bậc %d: %s -> %s)", 
                    context.serviceName(), 
                    i + 1, 
                    tierStart.toPlainString(), 
                    tierEnd != null ? tierEnd.toPlainString() : "trở lên");
                    
                details.add(new InvoiceDetail(
                    description,
                    consumptionInTier,
                    tier.pricePerUnit(),
                    context.serviceId()
                ));
                remainingConsumption = remainingConsumption.subtract(consumptionInTier);
            }
        }
        
        return details;
    }

    @Override
    public boolean supports(String chargeType, boolean hasTiers) {
        return "PER_INDEX".equals(chargeType) && hasTiers;
    }
}

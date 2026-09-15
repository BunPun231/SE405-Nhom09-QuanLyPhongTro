package com.roomrental.modules.finance.application.strategy;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;
import java.util.List;

public interface BillingStrategy {
    List<InvoiceDetail> calculate(BillingContext context);
    boolean supports(String chargeType, boolean hasTiers);
}

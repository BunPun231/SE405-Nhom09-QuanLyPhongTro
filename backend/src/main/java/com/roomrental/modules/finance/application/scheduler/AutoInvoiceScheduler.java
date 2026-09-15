package com.roomrental.modules.finance.application.scheduler;

import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.finance.application.service.InvoiceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.UUID;

@Component
public class AutoInvoiceScheduler {
    private static final Logger log = LoggerFactory.getLogger(AutoInvoiceScheduler.class);

    private final ContractRepository contractRepository;
    private final InvoiceService invoiceService;

    public AutoInvoiceScheduler(ContractRepository contractRepository, InvoiceService invoiceService) {
        this.contractRepository = contractRepository;
        this.invoiceService = invoiceService;
    }

    /**
     * Runs daily at 1:00 AM to scan and auto-generate invoices for active contracts matching the billing cycle.
     */
    @Scheduled(cron = "0 0 1 * * ?")
    public void runAutoInvoiceGeneration() {
        log.info("Starting scheduled auto-invoice generation job...");
        LocalDate today = LocalDate.now();
        List<Contract> activeContracts = contractRepository.findAllActiveContractsNative();
        
        log.info("Found {} active contracts to check for auto-billing", activeContracts.size());

        for (Contract contract : activeContracts) {
            try {
                int billingCycleDay = contract.getBillingCycleDay() != null ? contract.getBillingCycleDay() : 31;
                int todayDay = today.getDayOfMonth();
                int lastDayOfTodayMonth = today.lengthOfMonth();

                boolean isBillingDay = (todayDay == billingCycleDay) || 
                                      (billingCycleDay > lastDayOfTodayMonth && todayDay == lastDayOfTodayMonth);

                if (!isBillingDay) {
                    continue;
                }

                int paymentCycleMonths = contract.getPaymentCycleMonths() != null ? contract.getPaymentCycleMonths() : 1;
                LocalDate startDate = contract.getStartDate();
                if (startDate == null) {
                    continue;
                }

                int monthsBetween = (int) Period.between(startDate.withDayOfMonth(1), today.withDayOfMonth(1)).toTotalMonths();
                boolean isBillingMonth = (monthsBetween >= 0) && (monthsBetween % paymentCycleMonths == 0);

                if (!isBillingMonth) {
                    continue;
                }

                log.info("Contract ID {} matches auto-billing criteria today. Generating invoice.", contract.getId());
                
                // Emulate TenantContext and SecurityContext for background execution safety
                String prevTenantId = TenantContext.getCurrentTenantId();
                var prevAuth = SecurityContextHolder.getContext().getAuthentication();

                try {
                    TenantContext.setCurrentTenantId(contract.getTenantId().toString());
                    
                    UUID systemUserId = UUID.fromString("00000000-0000-0000-0000-000000000000");
                    SecurityContextHolder.getContext().setAuthentication(
                        new UsernamePasswordAuthenticationToken(
                            systemUserId.toString(),
                            null,
                            List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))
                        )
                    );

                    LocalDate billingMonth = today.withDayOfMonth(1);
                    invoiceService.generateForSingleContract(contract, billingMonth);
                } finally {
                    if (prevTenantId != null) {
                        TenantContext.setCurrentTenantId(prevTenantId);
                    } else {
                        TenantContext.clear();
                    }
                    SecurityContextHolder.getContext().setAuthentication(prevAuth);
                }

            } catch (Exception ex) {
                log.error("Failed to execute auto-billing for contract ID {}", contract.getId(), ex);
            }
        }
        
        log.info("Completed scheduled auto-invoice generation job.");
    }
}

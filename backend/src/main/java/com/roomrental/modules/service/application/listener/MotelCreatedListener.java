package com.roomrental.modules.service.application.listener;

import com.roomrental.common.util.TenantContext;
import com.roomrental.modules.motel.application.event.MotelCreatedEvent;
import com.roomrental.modules.service.application.dto.ServiceCreateCommand;
import com.roomrental.modules.service.application.dto.ServiceTierPricingCommand;
import com.roomrental.modules.service.application.service.RentalServiceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Component
public class MotelCreatedListener {
    private static final Logger log = LoggerFactory.getLogger(MotelCreatedListener.class);
    
    private final RentalServiceService rentalServiceService;

    public MotelCreatedListener(RentalServiceService rentalServiceService) {
        this.rentalServiceService = rentalServiceService;
    }

    /**
     * Listens for MotelCreatedEvent to auto-provision Electricity and Water services for new motels.
     */
    @EventListener
    public void handleMotelCreated(MotelCreatedEvent event) {
        log.info("Received MotelCreatedEvent for motelId={}, tenantId={}", event.motelId(), event.tenantId());
        
        String prevTenantId = TenantContext.getCurrentTenantId();
        var prevAuth = SecurityContextHolder.getContext().getAuthentication();
        
        try {
            TenantContext.setCurrentTenantId(event.tenantId().toString());
            
            if (prevAuth == null) {
                SecurityContextHolder.getContext().setAuthentication(
                    new UsernamePasswordAuthenticationToken(
                        event.actorId() != null ? event.actorId().toString() : "00000000-0000-0000-0000-000000000000",
                        null,
                        List.of(new SimpleGrantedAuthority("ROLE_MANAGER"))
                    )
                );
            }

            // Create electricity with tiered pricing commands (6 standard tiers in VN)
            List<ServiceTierPricingCommand> electricTiers = new ArrayList<>();
            electricTiers.add(new ServiceTierPricingCommand(BigDecimal.valueOf(0), BigDecimal.valueOf(50), BigDecimal.valueOf(1806)));
            electricTiers.add(new ServiceTierPricingCommand(BigDecimal.valueOf(50), BigDecimal.valueOf(100), BigDecimal.valueOf(1866)));
            electricTiers.add(new ServiceTierPricingCommand(BigDecimal.valueOf(100), BigDecimal.valueOf(200), BigDecimal.valueOf(2167)));
            electricTiers.add(new ServiceTierPricingCommand(BigDecimal.valueOf(200), BigDecimal.valueOf(300), BigDecimal.valueOf(2729)));
            electricTiers.add(new ServiceTierPricingCommand(BigDecimal.valueOf(300), BigDecimal.valueOf(400), BigDecimal.valueOf(3050)));
            electricTiers.add(new ServiceTierPricingCommand(BigDecimal.valueOf(400), null, BigDecimal.valueOf(3151)));

            rentalServiceService.create(event.motelId(), new ServiceCreateCommand(
                "Điện",
                "PER_INDEX",
                "kWh",
                true,
                BigDecimal.ZERO,
                electricTiers
            ));
            
            // Create water with standard flat rate (15000 đ/m3)
            rentalServiceService.create(event.motelId(), new ServiceCreateCommand(
                "Nước",
                "METERED",
                "m3",
                true,
                BigDecimal.valueOf(15000),
                List.of()
            ));
            
            log.info("Successfully pre-created standard tiered Electricity and Water services for motelId={}", event.motelId());
        } catch (Exception e) {
            log.error("Failed to auto-create default services for motelId={}", event.motelId(), e);
        } finally {
            if (prevTenantId != null) {
                TenantContext.setCurrentTenantId(prevTenantId);
            } else {
                TenantContext.clear();
            }
            SecurityContextHolder.getContext().setAuthentication(prevAuth);
        }
    }
}

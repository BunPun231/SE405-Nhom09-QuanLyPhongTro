package com.roomrental.modules.service.domain.repository;

import com.roomrental.modules.service.domain.model.ServicePricing;

import java.time.LocalDate;
import java.util.Optional;

public interface ServicePricingRepository {
    ServicePricing save(ServicePricing pricing);

    Optional<ServicePricing> findCurrentByServiceId(Long serviceId, LocalDate onDate);

    Optional<ServicePricing> findLatestByServiceId(Long serviceId);

    void closeCurrentPricing(Long serviceId, LocalDate effectiveTo);
}
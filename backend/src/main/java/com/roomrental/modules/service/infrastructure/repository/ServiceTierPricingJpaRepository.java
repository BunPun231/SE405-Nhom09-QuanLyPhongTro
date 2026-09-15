package com.roomrental.modules.service.infrastructure.repository;

import com.roomrental.modules.service.infrastructure.entity.ServiceTierPricingEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ServiceTierPricingJpaRepository extends JpaRepository<ServiceTierPricingEntity, Long> {
    List<ServiceTierPricingEntity> findByPricingIdOrderByTierStartAsc(Long pricingId);

    void deleteByPricingId(Long pricingId);
}
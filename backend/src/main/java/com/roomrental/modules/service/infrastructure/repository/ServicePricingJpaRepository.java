package com.roomrental.modules.service.infrastructure.repository;

import com.roomrental.modules.service.infrastructure.entity.ServicePricingEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface ServicePricingJpaRepository extends JpaRepository<ServicePricingEntity, Long> {
    Optional<ServicePricingEntity> findTopByServiceIdAndEffectiveFromLessThanEqualAndEffectiveToIsNullOrderByEffectiveFromDesc(Long serviceId, LocalDate onDate);

    Optional<ServicePricingEntity> findTopByServiceIdAndEffectiveFromLessThanEqualOrderByEffectiveFromDesc(Long serviceId, LocalDate onDate);

    List<ServicePricingEntity> findByServiceIdOrderByEffectiveFromDesc(Long serviceId);

    List<ServicePricingEntity> findByServiceIdAndEffectiveToIsNull(Long serviceId);
}
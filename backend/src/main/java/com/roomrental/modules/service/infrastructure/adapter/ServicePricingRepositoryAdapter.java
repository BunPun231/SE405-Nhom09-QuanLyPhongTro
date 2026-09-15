package com.roomrental.modules.service.infrastructure.adapter;

import com.roomrental.modules.service.domain.model.ServicePricing;
import com.roomrental.modules.service.domain.model.ServiceTierPricing;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import com.roomrental.modules.service.infrastructure.entity.ServicePricingEntity;
import com.roomrental.modules.service.infrastructure.entity.ServiceTierPricingEntity;
import com.roomrental.modules.service.infrastructure.repository.ServicePricingJpaRepository;
import com.roomrental.modules.service.infrastructure.repository.ServiceTierPricingJpaRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Component
public class ServicePricingRepositoryAdapter implements ServicePricingRepository {

    private final ServicePricingJpaRepository pricingJpaRepository;
    private final ServiceTierPricingJpaRepository tierJpaRepository;

    public ServicePricingRepositoryAdapter(
            ServicePricingJpaRepository pricingJpaRepository,
            ServiceTierPricingJpaRepository tierJpaRepository) {
        this.pricingJpaRepository = pricingJpaRepository;
        this.tierJpaRepository = tierJpaRepository;
    }

    @Override
    @Transactional
    public ServicePricing save(ServicePricing pricing) {
        ServicePricingEntity entity = toEntity(pricing);
        ServicePricingEntity saved = pricingJpaRepository.save(entity);
        if (pricing.getTierPrices() != null && !pricing.getTierPrices().isEmpty()) {
            tierJpaRepository.deleteByPricingId(saved.getId());
            List<ServiceTierPricingEntity> tierEntities = pricing.getTierPrices().stream()
                    .map(t -> toEntity(saved.getId(), t))
                    .toList();
            tierJpaRepository.saveAll(tierEntities);
        }
        return toDomain(saved);
    }

    @Override
    public Optional<ServicePricing> findCurrentByServiceId(Long serviceId, LocalDate onDate) {
        return pricingJpaRepository
                .findTopByServiceIdAndEffectiveFromLessThanEqualOrderByEffectiveFromDesc(serviceId, onDate)
                .map(this::toDomainWithTiers);
    }

    @Override
    public Optional<ServicePricing> findLatestByServiceId(Long serviceId) {
        return pricingJpaRepository.findByServiceIdOrderByEffectiveFromDesc(serviceId).stream()
                .findFirst()
                .map(this::toDomainWithTiers);
    }

    @Override
    @Transactional
    public void closeCurrentPricing(Long serviceId, LocalDate effectiveTo) {
        pricingJpaRepository.findByServiceIdAndEffectiveToIsNull(serviceId).forEach(entity -> {
            entity.setEffectiveTo(effectiveTo);
            pricingJpaRepository.save(entity);
        });
    }

    private ServicePricingEntity toEntity(ServicePricing pricing) {
        ServicePricingEntity entity = new ServicePricingEntity();
        entity.setId(pricing.getId());
        entity.setServiceId(pricing.getServiceId());
        entity.setEffectiveFrom(pricing.getEffectiveFrom());
        entity.setEffectiveTo(pricing.getEffectiveTo());
        entity.setBasePrice(pricing.getBasePrice());
        entity.setCreatedAt(pricing.getCreatedAt() != null ? pricing.getCreatedAt() : OffsetDateTime.now());
        return entity;
    }

    private ServicePricing toDomain(ServicePricingEntity entity) {
        ServicePricing pricing = new ServicePricing();
        pricing.setId(entity.getId());
        pricing.setServiceId(entity.getServiceId());
        pricing.setEffectiveFrom(entity.getEffectiveFrom());
        pricing.setEffectiveTo(entity.getEffectiveTo());
        pricing.setBasePrice(entity.getBasePrice());
        pricing.setCreatedAt(entity.getCreatedAt());
        return pricing;
    }

    private ServicePricing toDomainWithTiers(ServicePricingEntity entity) {
        ServicePricing pricing = toDomain(entity);
        List<ServiceTierPricing> tiers = tierJpaRepository.findByPricingIdOrderByTierStartAsc(entity.getId()).stream()
                .map(this::toDomain)
                .toList();
        pricing.setTierPrices(tiers);
        return pricing;
    }

    private ServiceTierPricingEntity toEntity(Long pricingId, ServiceTierPricing tier) {
        ServiceTierPricingEntity entity = new ServiceTierPricingEntity();
        entity.setPricingId(pricingId);
        entity.setTierStart(tier.getTierStart());
        entity.setTierEnd(tier.getTierEnd());
        entity.setPricePerUnit(tier.getPricePerUnit());
        entity.setCreatedAt(tier.getCreatedAt() != null ? tier.getCreatedAt() : OffsetDateTime.now());
        return entity;
    }

    private ServiceTierPricing toDomain(ServiceTierPricingEntity entity) {
        ServiceTierPricing tier = new ServiceTierPricing();
        tier.setId(entity.getId());
        tier.setPricingId(entity.getPricingId());
        tier.setTierStart(entity.getTierStart());
        tier.setTierEnd(entity.getTierEnd());
        tier.setPricePerUnit(entity.getPricePerUnit());
        tier.setCreatedAt(entity.getCreatedAt());
        return tier;
    }
}
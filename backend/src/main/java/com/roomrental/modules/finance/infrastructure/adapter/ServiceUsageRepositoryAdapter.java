package com.roomrental.modules.finance.infrastructure.adapter;

import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.model.ServiceUsage.ServiceUsageStatus;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.infrastructure.mapper.ServiceUsageMapper;
import com.roomrental.modules.finance.infrastructure.persistence.ServiceUsageEntity;
import com.roomrental.modules.finance.infrastructure.persistence.ServiceUsageJpaRepository;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Component
public class ServiceUsageRepositoryAdapter implements ServiceUsageRepository {

    private final ServiceUsageJpaRepository jpaRepository;
    private final ServiceUsageMapper mapper;

    public ServiceUsageRepositoryAdapter(ServiceUsageJpaRepository jpaRepository, ServiceUsageMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    public ServiceUsage save(ServiceUsage serviceUsage) {
        if (serviceUsage.getRegisteredAt() == null) {
            serviceUsage.setRegisteredAt(OffsetDateTime.now());
        }
        return mapper.toDomain(jpaRepository.save(mapper.toEntity(serviceUsage)));
    }

    @Override
    public List<ServiceUsage> saveAll(List<ServiceUsage> serviceUsages) {
        List<ServiceUsageEntity> entities = serviceUsages.stream()
                .map(this::ensureRegisteredAt)
                .map(mapper::toEntity)
                .toList();
        return jpaRepository.saveAll(entities).stream().map(mapper::toDomain).toList();
    }

    @Override
    public Optional<ServiceUsage> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<ServiceUsage> findActiveByRoomIdAndServiceId(Long roomId, Long serviceId) {
        return jpaRepository.findByRoomIdAndServiceIdAndStatus(roomId, serviceId, ServiceUsageStatus.ACTIVE)
                .map(mapper::toDomain);
    }

    @Override
    public List<ServiceUsage> findActiveByRoomId(Long roomId) {
        return jpaRepository.findByRoomIdAndStatus(roomId, ServiceUsageStatus.ACTIVE).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public List<ServiceUsage> findBillableByRoomId(Long roomId) {
        return jpaRepository.findByRoomIdAndStatusIn(roomId, List.of(ServiceUsageStatus.ACTIVE, ServiceUsageStatus.PENDING_CANCELLATION)).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public List<ServiceUsage> findByRoomId(Long roomId) {
        return jpaRepository.findByRoomId(roomId).stream().map(mapper::toDomain).toList();
    }

    private ServiceUsage ensureRegisteredAt(ServiceUsage usage) {
        if (usage.getRegisteredAt() == null) {
            usage.setRegisteredAt(OffsetDateTime.now());
        }
        return usage;
    }
}
package com.roomrental.modules.finance.domain.repository;

import com.roomrental.modules.finance.domain.model.ServiceUsage;

import java.util.List;
import java.util.Optional;

public interface ServiceUsageRepository {
    ServiceUsage save(ServiceUsage serviceUsage);

    List<ServiceUsage> saveAll(List<ServiceUsage> serviceUsages);

    Optional<ServiceUsage> findById(Long id);

    Optional<ServiceUsage> findActiveByRoomIdAndServiceId(Long roomId, Long serviceId);

    List<ServiceUsage> findActiveByRoomId(Long roomId);

    List<ServiceUsage> findBillableByRoomId(Long roomId);

    List<ServiceUsage> findByRoomId(Long roomId);
}
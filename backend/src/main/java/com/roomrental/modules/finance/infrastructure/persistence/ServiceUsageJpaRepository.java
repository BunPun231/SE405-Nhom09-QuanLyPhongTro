package com.roomrental.modules.finance.infrastructure.persistence;

import com.roomrental.modules.finance.domain.model.ServiceUsage.ServiceUsageStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ServiceUsageJpaRepository extends JpaRepository<ServiceUsageEntity, Long> {
    Optional<ServiceUsageEntity> findByRoomIdAndServiceIdAndStatus(Long roomId, Long serviceId, ServiceUsageStatus status);

    List<ServiceUsageEntity> findByRoomIdAndStatus(Long roomId, ServiceUsageStatus status);

    List<ServiceUsageEntity> findByRoomIdAndStatusIn(Long roomId, List<ServiceUsageStatus> statuses);

    List<ServiceUsageEntity> findByRoomId(Long roomId);
}
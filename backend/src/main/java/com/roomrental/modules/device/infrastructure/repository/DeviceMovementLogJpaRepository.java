package com.roomrental.modules.device.infrastructure.repository;

import com.roomrental.modules.device.infrastructure.entity.DeviceMovementLogEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DeviceMovementLogJpaRepository extends JpaRepository<DeviceMovementLogEntity, Long> {
    List<DeviceMovementLogEntity> findByDeviceIdOrderByTimestampDesc(Long deviceId);
}

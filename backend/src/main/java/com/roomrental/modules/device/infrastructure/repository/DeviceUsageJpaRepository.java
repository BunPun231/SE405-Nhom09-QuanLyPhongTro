package com.roomrental.modules.device.infrastructure.repository;

import com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceUsageJpaRepository extends JpaRepository<DeviceUsageEntity, Long> {
    List<DeviceUsageEntity> findByRoomId(Long roomId);
    List<DeviceUsageEntity> findByDeviceId(Long deviceId);
    Optional<DeviceUsageEntity> findByDeviceIdAndRoomId(Long deviceId, Long roomId);
}

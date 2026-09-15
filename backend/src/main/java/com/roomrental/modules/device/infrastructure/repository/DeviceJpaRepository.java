package com.roomrental.modules.device.infrastructure.repository;

import com.roomrental.modules.device.infrastructure.entity.DeviceEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DeviceJpaRepository extends JpaRepository<DeviceEntity, Long> {
    Optional<DeviceEntity> findByIdAndMotelId(Long id, Long motelId);
    Page<DeviceEntity> findByMotelId(Long motelId, Pageable pageable);
}

package com.roomrental.modules.device.domain.repository;

import com.roomrental.modules.device.domain.model.Device;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;

public interface DeviceRepository {
    Device save(Device device);
    Optional<Device> findByIdAndMotelId(Long id, Long motelId);
    Page<Device> findByMotelId(Long motelId, Pageable pageable);
}

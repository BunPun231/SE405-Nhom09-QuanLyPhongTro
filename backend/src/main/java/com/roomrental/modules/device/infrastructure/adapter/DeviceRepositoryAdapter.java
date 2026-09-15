package com.roomrental.modules.device.infrastructure.adapter;

import com.roomrental.modules.device.domain.model.Device;
import com.roomrental.modules.device.domain.repository.DeviceRepository;
import com.roomrental.modules.device.infrastructure.mapper.DevicePersistenceMapper;
import com.roomrental.modules.device.infrastructure.repository.DeviceJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class DeviceRepositoryAdapter implements DeviceRepository {

    private final DeviceJpaRepository jpa;
    private final DevicePersistenceMapper mapper;

    public DeviceRepositoryAdapter(DeviceJpaRepository jpa, DevicePersistenceMapper mapper) {
        this.jpa = jpa;
        this.mapper = mapper;
    }

    @Override
    public Device save(Device device) { return mapper.toDomain(jpa.save(mapper.toEntity(device))); }

    @Override
    public Optional<Device> findByIdAndMotelId(Long id, Long motelId) {
        return jpa.findByIdAndMotelId(id, motelId).map(mapper::toDomain);
    }

    @Override
    public Page<Device> findByMotelId(Long motelId, Pageable pageable) {
        return jpa.findByMotelId(motelId, pageable).map(mapper::toDomain);
    }
}

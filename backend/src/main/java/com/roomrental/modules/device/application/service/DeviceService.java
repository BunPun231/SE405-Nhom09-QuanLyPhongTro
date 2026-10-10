package com.roomrental.modules.device.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.device.application.dto.*;
import com.roomrental.modules.device.application.event.DeviceCreatedEvent;
import com.roomrental.modules.device.application.event.DeviceDeletedEvent;
import com.roomrental.modules.device.application.event.DeviceUpdatedEvent;
import com.roomrental.modules.device.domain.model.Device;
import com.roomrental.modules.device.domain.model.DeviceStatus;
import com.roomrental.modules.device.domain.repository.DeviceRepository;
import com.roomrental.modules.device.infrastructure.entity.DeviceMovementLogEntity;
import com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity;
import com.roomrental.modules.device.infrastructure.repository.DeviceMovementLogJpaRepository;
import com.roomrental.modules.device.infrastructure.repository.DeviceUsageJpaRepository;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Application service for Device management (UC40-UC47).
 */
@Service
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final DeviceUsageJpaRepository deviceUsageJpaRepository;
    private final DeviceMovementLogJpaRepository deviceMovementLogJpaRepository;
    private final MotelRepository motelRepository;
    private final RoomRepository roomRepository;
    private final ApplicationEventPublisher eventPublisher;

    public DeviceService(
            DeviceRepository deviceRepository,
            DeviceUsageJpaRepository deviceUsageJpaRepository,
            DeviceMovementLogJpaRepository deviceMovementLogJpaRepository,
            MotelRepository motelRepository,
            RoomRepository roomRepository,
            ApplicationEventPublisher eventPublisher) {
        this.deviceRepository = deviceRepository;
        this.deviceUsageJpaRepository = deviceUsageJpaRepository;
        this.deviceMovementLogJpaRepository = deviceMovementLogJpaRepository;
        this.motelRepository = motelRepository;
        this.roomRepository = roomRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public DeviceResult create(Long motelId, DeviceCreateCommand command) {
        requireMotel(motelId);

        Device device = new Device();
        device.setMotelId(motelId);
        device.setName(command.name());
        device.setBrand(command.brand());
        device.setPurchasePrice(command.purchasePrice());
        device.setPurchaseDate(command.purchaseDate());
        device.setStatus(DeviceStatus.IN_STOCK);

        DeviceResult result = toResult(deviceRepository.save(device));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new DeviceCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), result.name()));
        return result;
    }

    @Transactional(readOnly = true)
    public PageResponse<DeviceResult> list(Long motelId, Pageable pageable) {
        requireMotel(motelId);
        return PageResponse.from(deviceRepository.findByMotelId(motelId, pageable), this::toResult);
    }

    @Transactional(readOnly = true)
    public DeviceResult get(Long motelId, Long deviceId) {
        return toResult(findDevice(motelId, deviceId));
    }

    @Transactional
    public DeviceResult update(Long motelId, Long deviceId, DeviceUpdateCommand command) {
        Device device = findDevice(motelId, deviceId);
        String oldName = device.getName();

        if (command.name() != null) device.setName(command.name());
        if (command.brand() != null) device.setBrand(command.brand());
        if (command.purchasePrice() != null) device.setPurchasePrice(command.purchasePrice());
        if (command.purchaseDate() != null) device.setPurchaseDate(command.purchaseDate());
        if (command.status() != null) {
            try { device.setStatus(DeviceStatus.valueOf(command.status())); }
            catch (IllegalArgumentException e) { throw BaseException.badRequest("Invalid device status: " + command.status()); }
        }

        DeviceResult result = toResult(deviceRepository.save(device));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new DeviceUpdatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldName, result.name()));
        return result;
    }

    @Transactional
    public void delete(Long motelId, Long deviceId) {
        Device device = findDevice(motelId, deviceId);
        device.setDeleted(true);
        deviceRepository.save(device);

        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new DeviceDeletedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                deviceId, device.getName()));
    }

    @Transactional(readOnly = true)
    public List<DeviceUsageResult> getDevicesByRoom(Long motelId, Long roomId) {
        requireMotel(motelId);
        roomRepository.findByIdAndMotelId(roomId, motelId)
                .orElseThrow(() -> BaseException.notFound("Room", roomId));

        return deviceUsageJpaRepository.findByRoomId(roomId).stream()
                .map(usage -> {
                    Device device = deviceRepository.findById(usage.getDeviceId()).orElse(null);
                    String name = device != null ? device.getName() : "Unknown";
                    String brand = device != null ? device.getBrand() : "";
                    return new DeviceUsageResult(
                            usage.getId(), usage.getDeviceId(), name, brand,
                            usage.getRoomId(), usage.getAssignedQuantity(), usage.getCondition(),
                            usage.getAssignedAt(), usage.getUpdatedAt());
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public DeviceUsageResult assignDeviceToRoom(Long motelId, Long deviceId, DeviceAssignCommand command) {
        Device device = findDevice(motelId, deviceId);
        roomRepository.findByIdAndMotelId(command.roomId(), motelId)
                .orElseThrow(() -> BaseException.notFound("Room", command.roomId()));

        int qty = command.assignedQuantity() != null && command.assignedQuantity() > 0 ? command.assignedQuantity() : 1;
        String cond = command.condition() != null ? command.condition() : "GOOD";

        DeviceUsageEntity usage = deviceUsageJpaRepository.findByDeviceIdAndRoomId(deviceId, command.roomId())
                .orElseGet(DeviceUsageEntity::new);

        usage.setDeviceId(deviceId);
        usage.setRoomId(command.roomId());
        usage.setAssignedQuantity(qty);
        usage.setCondition(cond);
        usage.setUpdatedAt(OffsetDateTime.now());

        DeviceUsageEntity savedUsage = deviceUsageJpaRepository.save(usage);

        // Update device status to IN_USE
        device.setStatus(DeviceStatus.IN_USE);
        deviceRepository.save(device);

        // Movement log
        DeviceMovementLogEntity log = new DeviceMovementLogEntity();
        log.setDeviceId(deviceId);
        log.setFromRoomId(null);
        log.setToRoomId(command.roomId());
        log.setAction("ASSIGN");
        log.setChangedBy(SecurityUtils.getCurrentUserId());
        log.setNote(command.note());
        deviceMovementLogJpaRepository.save(log);

        return new DeviceUsageResult(
                savedUsage.getId(), deviceId, device.getName(), device.getBrand(),
                command.roomId(), savedUsage.getAssignedQuantity(), savedUsage.getCondition(),
                savedUsage.getAssignedAt(), savedUsage.getUpdatedAt());
    }

    @Transactional
    public void recallDeviceFromRoom(Long motelId, Long deviceId, Long roomId, String note) {
        Device device = findDevice(motelId, deviceId);
        DeviceUsageEntity usage = deviceUsageJpaRepository.findByDeviceIdAndRoomId(deviceId, roomId)
                .orElseThrow(() -> BaseException.notFound("DeviceUsage for room", roomId));

        deviceUsageJpaRepository.delete(usage);

        // Check if device is still assigned elsewhere
        List<DeviceUsageEntity> remainingUsages = deviceUsageJpaRepository.findByDeviceId(deviceId);
        if (remainingUsages.isEmpty()) {
            device.setStatus(DeviceStatus.IN_STOCK);
            deviceRepository.save(device);
        }

        // Movement log
        DeviceMovementLogEntity log = new DeviceMovementLogEntity();
        log.setDeviceId(deviceId);
        log.setFromRoomId(roomId);
        log.setToRoomId(null);
        log.setAction("RECALL");
        log.setChangedBy(SecurityUtils.getCurrentUserId());
        log.setNote(note);
        deviceMovementLogJpaRepository.save(log);
    }

    @Transactional(readOnly = true)
    public List<DeviceMovementLogResult> getMovementLogs(Long motelId, Long deviceId) {
        findDevice(motelId, deviceId);
        return deviceMovementLogJpaRepository.findByDeviceIdOrderByTimestampDesc(deviceId).stream()
                .map(l -> new DeviceMovementLogResult(
                        l.getId(), l.getDeviceId(), l.getFromRoomId(), l.getToRoomId(),
                        l.getAction(), l.getChangedBy(), l.getTimestamp(), l.getNote()))
                .collect(Collectors.toList());
    }

    private Motel requireMotel(Long motelId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return motelRepository.findByIdAndTenantId(motelId, tenantId)
                .orElseThrow(() -> BaseException.notFound("Motel", motelId));
    }

    private Device findDevice(Long motelId, Long deviceId) {
        requireMotel(motelId);
        return deviceRepository.findByIdAndMotelId(deviceId, motelId)
                .orElseThrow(() -> BaseException.notFound("Device", deviceId));
    }

    private DeviceResult toResult(Device d) {
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(d.getId()).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        return new DeviceResult(d.getId(), d.getMotelId(), d.getName(), d.getBrand(),
                d.getPurchasePrice(), d.getPurchaseDate(), d.getStatus().name(), inUseQty);
    }
}

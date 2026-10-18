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

        int initQty = command.totalQuantity() != null && command.totalQuantity() > 0 ? command.totalQuantity() : 1;
        Device device = new Device();
        device.setMotelId(motelId);
        device.setName(command.name());
        device.setBrand(command.brand());
        device.setPurchasePrice(command.purchasePrice());
        device.setPurchaseDate(command.purchaseDate());
        device.setTotalQuantity(initQty);
        device.setStatus(DeviceStatus.IN_STOCK);

        Device saved = deviceRepository.save(device);

        // Movement log: lưu lịch sử số lượng ban đầu khi tạo thiết bị nhập kho
        recordMovementLog(saved, null, null, "IMPORT", initQty, "Khởi tạo thiết bị vào kho");

        DeviceResult result = toResult(saved);
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new DeviceCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), result.name()));
        return result;
    }

    @Transactional(readOnly = true)
    public PageResponse<DeviceResult> list(Long motelId, boolean includeDeleted, Pageable pageable) {
        requireMotel(motelId);
        return PageResponse.from(deviceRepository.findByMotelId(motelId, includeDeleted, pageable), this::toResult);
    }

    @Transactional(readOnly = true)
    public PageResponse<DeviceResult> list(Long motelId, Pageable pageable) {
        return list(motelId, false, pageable);
    }

    @Transactional(readOnly = true)
    public DeviceResult get(Long motelId, Long deviceId) {
        return toResult(findDeviceIncludingDeleted(motelId, deviceId));
    }

    @Transactional
    public DeviceResult update(Long motelId, Long deviceId, DeviceUpdateCommand command) {
        Device device = findDevice(motelId, deviceId);
        String oldName = device.getName();

        if (command.name() != null) device.setName(command.name());
        if (command.brand() != null) device.setBrand(command.brand());
        if (command.purchasePrice() != null) device.setPurchasePrice(command.purchasePrice());
        if (command.purchaseDate() != null) device.setPurchaseDate(command.purchaseDate());

        // totalQuantity and status are locked in update - calculated automatically based on available stock
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(deviceId).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        int availableQty = device.getTotalQuantity() - inUseQty - device.getRepairingQuantity();
        device.setStatus(availableQty > 0 ? DeviceStatus.IN_STOCK : DeviceStatus.IN_USE);

        DeviceResult result = toResult(deviceRepository.save(device));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new DeviceUpdatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldName, result.name()));
        return result;
    }

    @Transactional
    public DeviceResult importStock(Long motelId, Long deviceId, DeviceImportCommand command) {
        if (command.quantity() == null || command.quantity() <= 0) {
            throw BaseException.badRequest("Số lượng nhập kho phải lớn hơn 0");
        }
        Device device = findDevice(motelId, deviceId);
        device.setTotalQuantity(device.getTotalQuantity() + command.quantity());
        device.setStatus(computeStatus(device));
        Device saved = deviceRepository.save(device);

        recordMovementLog(saved, null, null, "IMPORT", command.quantity(), command.note());

        return toResult(saved);
    }

    @Transactional
    public DeviceResult disposeStock(Long motelId, Long deviceId, DeviceDisposeCommand command) {
        if (command.quantity() == null || command.quantity() <= 0) {
            throw BaseException.badRequest("Số lượng xuất hủy phải lớn hơn 0");
        }
        Device device = findDevice(motelId, deviceId);

        int inUseQty = deviceUsageJpaRepository.findByDeviceId(deviceId).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        int repairingQty = device.getRepairingQuantity();
        int availableQty = device.getTotalQuantity() - inUseQty - repairingQty;
        if (availableQty <= 0 || command.quantity() > availableQty) {
            throw BaseException.badRequest("Số lượng khả dụng trong kho không đủ (Hiện có: " + Math.max(0, availableQty) + ")");
        }

        device.setTotalQuantity(device.getTotalQuantity() - command.quantity());
        device.setStatus(computeStatus(device));
        Device saved = deviceRepository.save(device);

        recordMovementLog(saved, null, null, "DISPOSE", command.quantity(), command.reason());

        return toResult(saved);
    }

    @Transactional
    public void delete(Long motelId, Long deviceId) {
        Device device = findDevice(motelId, deviceId);
        
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(deviceId).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        if (inUseQty > 0) {
            throw BaseException.badRequest("Không thể xóa thiết bị đang được gán tại phòng (" + inUseQty + " thiết bị đang gán)");
        }

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

        if (command.assignedQuantity() == null || command.assignedQuantity() <= 0) {
            throw BaseException.badRequest("Số lượng gán phải lớn hơn 0");
        }
        int requestedQty = command.assignedQuantity();
        String cond = command.condition() != null ? command.condition() : "GOOD";
        if ("string".equalsIgnoreCase(cond) || (!cond.equals("NEW") && !cond.equals("GOOD") && !cond.equals("BROKEN"))) {
            cond = "GOOD";
        }

        List<DeviceUsageEntity> usages = deviceUsageJpaRepository.findByDeviceId(deviceId);
        int currentInUseExceptThisRoom = usages.stream()
                .filter(u -> !u.getRoomId().equals(command.roomId()))
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();

        int availableForThisRoom = device.getTotalQuantity() - currentInUseExceptThisRoom - device.getRepairingQuantity();
        if (availableForThisRoom <= 0 || requestedQty > availableForThisRoom) {
            throw BaseException.badRequest("Số lượng khả dụng trong kho không đủ (Hiện có: " + Math.max(0, availableForThisRoom) + ")");
        }

        DeviceUsageEntity usage = deviceUsageJpaRepository.findByDeviceIdAndRoomId(deviceId, command.roomId())
                .orElseGet(DeviceUsageEntity::new);

        usage.setDeviceId(deviceId);
        usage.setRoomId(command.roomId());
        usage.setAssignedQuantity(requestedQty);
        usage.setCondition(cond);
        usage.setUpdatedAt(OffsetDateTime.now());

        DeviceUsageEntity savedUsage = deviceUsageJpaRepository.save(usage);

        // Update device auto-status based on available inventory
        int newTotalInUse = currentInUseExceptThisRoom + requestedQty;
        int newAvailable = device.getTotalQuantity() - newTotalInUse - device.getRepairingQuantity();
        device.setStatus(newAvailable > 0 ? DeviceStatus.IN_STOCK : DeviceStatus.IN_USE);
        deviceRepository.save(device);

        recordMovementLog(device, null, command.roomId(), "ASSIGN", requestedQty, command.note());

        return new DeviceUsageResult(
                savedUsage.getId(), deviceId, device.getName(), device.getBrand(),
                command.roomId(), savedUsage.getAssignedQuantity(), savedUsage.getCondition(),
                savedUsage.getAssignedAt(), savedUsage.getUpdatedAt());
    }

    @Transactional
    public void recallDeviceFromRoom(Long motelId, Long deviceId, Long roomId, DeviceRecallCommand command) {
        Device device = findDevice(motelId, deviceId);
        DeviceUsageEntity usage = deviceUsageJpaRepository.findByDeviceIdAndRoomId(deviceId, roomId)
                .orElseThrow(() -> BaseException.notFound("DeviceUsage for room", roomId));

        Integer reqQty = command != null ? command.quantity() : null;
        if (reqQty != null && (reqQty <= 0 || reqQty > usage.getAssignedQuantity())) {
            throw BaseException.badRequest("Số lượng thu hồi không được vượt quá số lượng đang gán tại phòng");
        }

        int currentAssigned = usage.getAssignedQuantity();
        int recalledQty;

        if (reqQty == null || reqQty >= currentAssigned) {
            recalledQty = currentAssigned;
            deviceUsageJpaRepository.delete(usage);
        } else {
            recalledQty = reqQty;
            usage.setAssignedQuantity(currentAssigned - reqQty);
            usage.setUpdatedAt(OffsetDateTime.now());
            deviceUsageJpaRepository.save(usage);
        }

        // Recalculate remaining in-use quantity and update device status automatically
        int remainingInUse = deviceUsageJpaRepository.findByDeviceId(deviceId).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        int availableQty = device.getTotalQuantity() - remainingInUse - device.getRepairingQuantity();
        device.setStatus(availableQty > 0 ? DeviceStatus.IN_STOCK : DeviceStatus.IN_USE);
        deviceRepository.save(device);

        recordMovementLog(device, roomId, null, "RECALL", recalledQty, command != null ? command.note() : null);
    }

    @Transactional
    public void recallDeviceFromRoom(Long motelId, Long deviceId, Long roomId, String note) {
        recallDeviceFromRoom(motelId, deviceId, roomId, new DeviceRecallCommand(null, note));
    }

    @Transactional(readOnly = true)
    public List<DeviceMovementLogResult> getMovementLogs(Long motelId, Long deviceId) {
        findDeviceIncludingDeleted(motelId, deviceId);
        return deviceMovementLogJpaRepository.findByDeviceIdOrderByTimestampDesc(deviceId).stream()
                .map(l -> new DeviceMovementLogResult(
                        l.getId(), l.getDeviceId(), l.getFromRoomId(), l.getToRoomId(),
                        l.getAction(), l.getQuantity(), l.getChangedBy(), l.getTimestamp(), l.getNote(),
                        l.getSnapshotTotalQuantity(), l.getSnapshotAvailableQuantity(),
                        l.getSnapshotRepairingQuantity(), l.getSnapshotInUseQuantity()))
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

    private Device findDeviceIncludingDeleted(Long motelId, Long deviceId) {
        requireMotel(motelId);
        return deviceRepository.findByIdAndMotelIdIncludingDeleted(deviceId, motelId)
                .orElseThrow(() -> BaseException.notFound("Device", deviceId));
    }

    private void recordMovementLog(Device device, Long fromRoomId, Long toRoomId, String action, int quantity, String note) {
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(device.getId()).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        int totalQty = device.getTotalQuantity();
        int repQty = device.getRepairingQuantity();
        int availQty = totalQty - inUseQty - repQty;

        DeviceMovementLogEntity log = new DeviceMovementLogEntity();
        log.setDeviceId(device.getId());
        log.setFromRoomId(fromRoomId);
        log.setToRoomId(toRoomId);
        log.setAction(action);
        log.setQuantity(quantity);
        log.setChangedBy(SecurityUtils.getCurrentUserId());
        log.setNote(note);
        log.setSnapshotTotalQuantity(totalQty);
        log.setSnapshotAvailableQuantity(availQty);
        log.setSnapshotInUseQuantity(inUseQty);
        log.setSnapshotRepairingQuantity(repQty);
        deviceMovementLogJpaRepository.save(log);
    }

    // Helper to compute status based on available quantity considering repairing devices
    private DeviceStatus computeStatus(Device device) {
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(device.getId()).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        int available = device.getTotalQuantity() - inUseQty - device.getRepairingQuantity();
        return available > 0 ? DeviceStatus.IN_STOCK : DeviceStatus.IN_USE;
    }

    private DeviceResult toResult(Device d) {
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(d.getId()).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                .sum();
        int repairingQty = d.getRepairingQuantity();
        int availableQty = d.getTotalQuantity() - inUseQty - repairingQty;
        String autoStatus = (availableQty > 0 ? DeviceStatus.IN_STOCK : DeviceStatus.IN_USE).name();
        return new DeviceResult(d.getId(), d.getMotelId(), d.getName(), d.getBrand(),
                d.getPurchasePrice(), d.getPurchaseDate(), d.getTotalQuantity(), inUseQty, repairingQty,
                Math.max(0, availableQty), autoStatus, d.isDeleted());
    }

    @Transactional
    public DeviceResult sendToRepair(Long motelId, Long deviceId, DeviceSendToRepairCommand command) {
        if (command.quantity() == null || command.quantity() <= 0) {
            throw BaseException.badRequest("Số lượng gửi bảo trì phải lớn hơn 0");
        }
        Device device = findDevice(motelId, deviceId);
        int inUseQty = deviceUsageJpaRepository.findByDeviceId(deviceId).stream()
                .mapToInt(DeviceUsageEntity::getAssignedQuantity).sum();
        int availableQty = device.getTotalQuantity() - inUseQty - device.getRepairingQuantity();
        if (command.quantity() > availableQty) {
            throw BaseException.badRequest("Số lượng gửi bảo trì (" + command.quantity() + ") vượt quá khả dụng (" + Math.max(0, availableQty) + ")");
        }
        device.setRepairingQuantity(device.getRepairingQuantity() + command.quantity());
        device.setStatus(computeStatus(device));
        Device saved = deviceRepository.save(device);

        recordMovementLog(saved, null, null, "SEND_TO_REPAIR", command.quantity(), command.note());

        return toResult(saved);
    }

    @Transactional
    public DeviceResult finishRepair(Long motelId, Long deviceId, DeviceFinishRepairCommand command) {
        if (command.quantity() == null || command.quantity() <= 0) {
            throw BaseException.badRequest("Số lượng hoàn thiện bảo trì phải lớn hơn 0");
        }
        Device device = findDevice(motelId, deviceId);
        if (command.quantity() > device.getRepairingQuantity()) {
            throw BaseException.badRequest("Số lượng hoàn thiện bảo trì (" + command.quantity() + ") vượt quá số lượng đang bảo trì (" + device.getRepairingQuantity() + ")");
        }
        device.setRepairingQuantity(device.getRepairingQuantity() - command.quantity());
        device.setStatus(computeStatus(device));
        Device saved = deviceRepository.save(device);

        recordMovementLog(saved, null, null, "FINISH_REPAIR", command.quantity(), command.note());

        return toResult(saved);
    }

}

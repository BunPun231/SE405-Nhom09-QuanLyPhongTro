package com.roomrental.modules.maintenance.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import com.roomrental.modules.device.domain.model.Device;
import com.roomrental.modules.device.domain.model.DeviceStatus;
import com.roomrental.modules.device.domain.repository.DeviceRepository;
import com.roomrental.modules.device.infrastructure.entity.DeviceMovementLogEntity;
import com.roomrental.modules.device.infrastructure.entity.DeviceUsageEntity;
import com.roomrental.modules.device.infrastructure.repository.DeviceMovementLogJpaRepository;
import com.roomrental.modules.device.infrastructure.repository.DeviceUsageJpaRepository;
import com.roomrental.modules.finance.application.service.CloudinaryService;
import com.roomrental.modules.maintenance.application.dto.*;
import com.roomrental.modules.maintenance.domain.model.MaintenanceCategory;
import com.roomrental.modules.maintenance.domain.model.MaintenancePriority;
import com.roomrental.modules.maintenance.domain.model.MaintenanceStatus;
import com.roomrental.modules.maintenance.infrastructure.entity.MaintenanceDetailEntity;
import com.roomrental.modules.maintenance.infrastructure.entity.MaintenanceTicketEntity;
import com.roomrental.modules.maintenance.infrastructure.repository.MaintenanceDetailJpaRepository;
import com.roomrental.modules.maintenance.infrastructure.repository.MaintenanceTicketJpaRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MaintenanceService {

    private final MaintenanceTicketJpaRepository ticketRepository;
    private final MaintenanceDetailJpaRepository detailRepository;
    private final RoomRepository roomRepository;
    private final DeviceRepository deviceRepository;
    private final DeviceUsageJpaRepository deviceUsageJpaRepository;
    private final DeviceMovementLogJpaRepository deviceMovementLogJpaRepository;
    private final UserJpaRepository userRepository;
    private final CloudinaryService cloudinaryService;

    public MaintenanceService(
            MaintenanceTicketJpaRepository ticketRepository,
            MaintenanceDetailJpaRepository detailRepository,
            RoomRepository roomRepository,
            DeviceRepository deviceRepository,
            DeviceUsageJpaRepository deviceUsageJpaRepository,
            DeviceMovementLogJpaRepository deviceMovementLogJpaRepository,
            UserJpaRepository userRepository,
            CloudinaryService cloudinaryService) {
        this.ticketRepository = ticketRepository;
        this.detailRepository = detailRepository;
        this.roomRepository = roomRepository;
        this.deviceRepository = deviceRepository;
        this.deviceUsageJpaRepository = deviceUsageJpaRepository;
        this.deviceMovementLogJpaRepository = deviceMovementLogJpaRepository;
        this.userRepository = userRepository;
        this.cloudinaryService = cloudinaryService;
    }

    @Transactional
    public MaintenanceTicketResult createTicket(CreateTicketCommand command) {
        UUID reporterId = SecurityUtils.getCurrentUserId();

        Room room = roomRepository.findById(command.roomId())
                .orElseThrow(() -> BaseException.notFound("Room", command.roomId()));

        // Upload before_images to Cloudinary if present
        List<String> imageUrls = new ArrayList<>();
        if (command.beforeImageFiles() != null && !command.beforeImageFiles().isEmpty()) {
            for (MultipartFile file : command.beforeImageFiles()) {
                if (file != null && !file.isEmpty()) {
                    try {
                        String url = cloudinaryService.uploadImage(file, "maintenance/before");
                        if (url != null) imageUrls.add(url);
                    } catch (IOException e) {
                        throw BaseException.badRequest("Failed to upload image: " + e.getMessage());
                    }
                }
            }
        }

        MaintenanceTicketEntity ticket = new MaintenanceTicketEntity();
        ticket.setRoomId(room.getId());
        ticket.setReportedBy(reporterId);
        
        String cat = MaintenanceCategory.OTHER.name();
        if (command.category() != null && !command.category().isBlank()) {
            try {
                cat = MaintenanceCategory.valueOf(command.category().trim().toUpperCase()).name();
            } catch (IllegalArgumentException e) {
                cat = MaintenanceCategory.OTHER.name();
            }
        }
        ticket.setCategory(cat);
        ticket.setDescription(command.description());
        ticket.setBeforeImages(imageUrls.toArray(String[]::new));
        ticket.setStatus(MaintenanceStatus.OPEN.name());

        String prio = MaintenancePriority.MEDIUM.name();
        if (command.priority() != null && !command.priority().isBlank()) {
            String raw = command.priority().trim();
            try {
                prio = MaintenancePriority.valueOf(raw.toUpperCase()).name();
            } catch (IllegalArgumentException e) {
                if ("1".equals(raw)) prio = MaintenancePriority.LOW.name();
                else if ("2".equals(raw)) prio = MaintenancePriority.MEDIUM.name();
                else if ("3".equals(raw)) prio = MaintenancePriority.HIGH.name();
                else if ("4".equals(raw)) prio = MaintenancePriority.URGENT.name();
                else prio = MaintenancePriority.MEDIUM.name();
            }
        }
        ticket.setPriority(prio);

        MaintenanceTicketEntity saved = ticketRepository.save(ticket);
        return toResult(saved);
    }

    @Transactional
    public MaintenanceTicketResult assignTicket(Long ticketId, AssignTicketCommand command) {
        MaintenanceTicketEntity ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> BaseException.notFound("MaintenanceTicket", ticketId));

        if (MaintenanceStatus.COMPLETED.name().equalsIgnoreCase(ticket.getStatus())) {
            throw BaseException.badRequest("Phiếu bảo trì đã hoàn thành không thể mở lại");
        }

        if (command.technicianId() != null) {
            userRepository.findById(command.technicianId())
                    .orElseThrow(() -> BaseException.notFound("Technician", command.technicianId()));
        }

        ticket.setAssignedTo(command.technicianId());
        ticket.setStatus(MaintenanceStatus.PROCESSING.name());
        ticket.setUpdatedAt(OffsetDateTime.now());

        MaintenanceTicketEntity saved = ticketRepository.save(ticket);
        return toResult(saved);
    }

    @Transactional
    public MaintenanceTicketResult completeTicket(Long ticketId, CompleteTicketCommand command) {
        MaintenanceTicketEntity ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> BaseException.notFound("MaintenanceTicket", ticketId));

        if (MaintenanceStatus.COMPLETED.name().equalsIgnoreCase(ticket.getStatus())) {
            throw BaseException.badRequest("Phiếu bảo trì đã hoàn thành không thể mở lại");
        }
        if (MaintenanceStatus.CANCELLED.name().equalsIgnoreCase(ticket.getStatus())) {
            throw BaseException.badRequest("Phiếu bảo trì đã bị hủy không thể hoàn thành");
        }

        Room room = roomRepository.findById(ticket.getRoomId())
                .orElseThrow(() -> BaseException.notFound("Room", ticket.getRoomId()));

        // Upload after_images to Cloudinary if present
        List<String> afterUrls = new ArrayList<>();
        if (command.afterImageFiles() != null && !command.afterImageFiles().isEmpty()) {
            for (MultipartFile file : command.afterImageFiles()) {
                if (file != null && !file.isEmpty()) {
                    try {
                        String url = cloudinaryService.uploadImage(file, "maintenance/after");
                        if (url != null) afterUrls.add(url);
                    } catch (IOException e) {
                        throw BaseException.badRequest("Failed to upload after image: " + e.getMessage());
                    }
                }
            }
        }

        // Save details for used devices and deduct inventory
        if (command.usedDevices() != null && !command.usedDevices().isEmpty()) {
            for (UsedDeviceItem item : command.usedDevices()) {
                if (item == null || item.deviceId() == null) continue;

                Device device = deviceRepository.findById(item.deviceId())
                        .orElseThrow(() -> BaseException.badRequest("Thiết bị không tồn tại với ID: " + item.deviceId()));

                if (!device.getMotelId().equals(room.getMotelId())) {
                    throw BaseException.badRequest("Thiết bị không thuộc nhà trọ của phòng này");
                }

                int qtyUsed = item.quantityUsed() != null && item.quantityUsed() > 0 ? item.quantityUsed() : 1;

                int inUseQty = deviceUsageJpaRepository.findByDeviceId(device.getId()).stream()
                        .mapToInt(DeviceUsageEntity::getAssignedQuantity)
                        .sum();
                int availableQty = device.getTotalQuantity() - inUseQty - device.getRepairingQuantity();
                if (qtyUsed > availableQty) {
                    throw BaseException.badRequest("Số lượng vật tư sử dụng (" + qtyUsed 
                            + ") vượt quá số lượng khả dụng trong kho (" + Math.max(0, availableQty) + ")");
                }

                // Trừ kho vật tư
                device.setTotalQuantity(device.getTotalQuantity() - qtyUsed);
                int newAvailable = device.getTotalQuantity() - inUseQty - device.getRepairingQuantity();
                device.setStatus(newAvailable > 0 ? DeviceStatus.IN_STOCK : DeviceStatus.IN_USE);
                deviceRepository.save(device);


                // Ghi nhật ký biến động kho (action = 'MAINTENANCE_USE')
                DeviceMovementLogEntity log = new DeviceMovementLogEntity();
                log.setDeviceId(device.getId());
                log.setFromRoomId(null);
                log.setToRoomId(ticket.getRoomId());
                log.setAction("MAINTENANCE_USE");
                log.setQuantity(qtyUsed);
                log.setChangedBy(SecurityUtils.getCurrentUserId());
                log.setNote("Sử dụng cho bảo trì phiếu #" + ticket.getId() + (command.note() != null ? ": " + command.note() : ""));
                log.setSnapshotTotalQuantity(device.getTotalQuantity());
                log.setSnapshotAvailableQuantity(newAvailable);
                log.setSnapshotInUseQuantity(inUseQty);
                log.setSnapshotRepairingQuantity(device.getRepairingQuantity());
                deviceMovementLogJpaRepository.save(log);

                BigDecimal price = item.unitPrice() != null ? item.unitPrice() :
                        (device.getPurchasePrice() != null ? device.getPurchasePrice() : BigDecimal.ZERO);

                MaintenanceDetailEntity detail = new MaintenanceDetailEntity();
                detail.setTicketId(ticketId);
                detail.setDeviceId(device.getId());
                detail.setQuantityUsed(qtyUsed);
                detail.setUnitPriceSnapshot(price);
                detail.setAfterImages(afterUrls.toArray(String[]::new));
                detail.setNote(command.note());
                detailRepository.save(detail);
            }
        } else if (!afterUrls.isEmpty() || (command.note() != null && !command.note().isBlank())) {
            // Create a general detail record if photos/notes provided without specific devices
            MaintenanceDetailEntity detail = new MaintenanceDetailEntity();
            detail.setTicketId(ticketId);
            detail.setDeviceId(null); // null indicates no device part replacement
            detail.setQuantityUsed(0);
            detail.setUnitPriceSnapshot(BigDecimal.ZERO);
            detail.setAfterImages(afterUrls.toArray(String[]::new));
            detail.setNote(command.note());
            detailRepository.save(detail);
        }

        ticket.setStatus(MaintenanceStatus.COMPLETED.name());
        ticket.setCompletedAt(OffsetDateTime.now());
        ticket.setUpdatedAt(OffsetDateTime.now());

        MaintenanceTicketEntity saved = ticketRepository.save(ticket);
        return toResult(saved);
    }
    @Transactional
    public MaintenanceTicketResult cancelTicket(Long ticketId) {
        MaintenanceTicketEntity ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> BaseException.notFound("MaintenanceTicket", ticketId));

        String status = ticket.getStatus();
        if (!"OPEN".equalsIgnoreCase(status) && !"ASSIGNED".equalsIgnoreCase(status) && !"PROCESSING".equalsIgnoreCase(status)) {
            throw BaseException.badRequest("Chỉ cho phép hủy khi phiếu đang ở trạng thái OPEN hoặc ASSIGNED");
        }

        ticket.setStatus(MaintenanceStatus.CANCELLED.name());
        ticket.setUpdatedAt(OffsetDateTime.now());
        MaintenanceTicketEntity saved = ticketRepository.save(ticket);
        return toResult(saved);
    }

    @Transactional
    public MaintenanceTicketResult updateTicket(Long ticketId, UpdateTicketCommand command) {
        MaintenanceTicketEntity ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> BaseException.notFound("MaintenanceTicket", ticketId));

        String status = ticket.getStatus();
        if ("COMPLETED".equalsIgnoreCase(status) || "CANCELLED".equalsIgnoreCase(status)) {
            throw BaseException.badRequest("Không thể chỉnh sửa phiếu bảo trì đã hoàn thành hoặc đã bị hủy");
        }

        if (command.category() != null && !command.category().isBlank()) {
            try {
                ticket.setCategory(MaintenanceCategory.valueOf(command.category().trim().toUpperCase()).name());
            } catch (IllegalArgumentException e) {
                // keep existing
            }
        }
        if (command.description() != null) {
            ticket.setDescription(command.description());
        }
        if (command.priority() != null && !command.priority().isBlank()) {
            String raw = command.priority().trim();
            try {
                ticket.setPriority(MaintenancePriority.valueOf(raw.toUpperCase()).name());
            } catch (IllegalArgumentException e) {
                // ignore
            }
        }
        ticket.setUpdatedAt(OffsetDateTime.now());
        MaintenanceTicketEntity saved = ticketRepository.save(ticket);
        return toResult(saved);
    }

    @Transactional(readOnly = true)
    public PageResponse<MaintenanceTicketResult> listForManager(Long motelId, Pageable pageable) {
        Page<Room> rooms = roomRepository.findByMotelId(motelId, Pageable.unpaged());
        List<Long> roomIds = rooms.getContent().stream().map(Room::getId).collect(Collectors.toList());

        if (roomIds.isEmpty()) {
            return PageResponse.from(Page.empty(pageable), this::toResult);
        }

        Page<MaintenanceTicketEntity> page = ticketRepository.findByRoomIdIn(roomIds, pageable);
        return PageResponse.from(page, this::toResult);
    }

    @Transactional(readOnly = true)
    public PageResponse<MaintenanceTicketResult> listForTechnician(Pageable pageable) {
        UUID techId = SecurityUtils.getCurrentUserId();
        Page<MaintenanceTicketEntity> page = ticketRepository.findByAssignedTo(techId, pageable);
        return PageResponse.from(page, this::toResult);
    }

    @Transactional(readOnly = true)
    public PageResponse<MaintenanceTicketResult> listForTenant(Pageable pageable) {
        UUID tenantUserId = SecurityUtils.getCurrentUserId();
        Page<MaintenanceTicketEntity> page = ticketRepository.findByReportedBy(tenantUserId, pageable);
        return PageResponse.from(page, this::toResult);
    }

    @Transactional(readOnly = true)
    public MaintenanceTicketResult getTicketDetail(Long ticketId) {
        MaintenanceTicketEntity ticket = ticketRepository.findById(ticketId)
                .orElseThrow(() -> BaseException.notFound("MaintenanceTicket", ticketId));
        return toResult(ticket);
    }

    private MaintenanceTicketResult toResult(MaintenanceTicketEntity ticket) {
        Room room = roomRepository.findById(ticket.getRoomId()).orElse(null);
        Long motelId = room != null ? room.getMotelId() : null;
        String roomNumber = room != null ? room.getRoomNumber() : "Unknown";

        UserEntity reporter = userRepository.findById(ticket.getReportedBy()).orElse(null);
        String reporterName = reporter != null ? reporter.getFullName() : "Unknown";

        String technicianName = null;
        if (ticket.getAssignedTo() != null) {
            UserEntity tech = userRepository.findById(ticket.getAssignedTo()).orElse(null);
            technicianName = tech != null ? tech.getFullName() : null;
        }

        List<MaintenanceDetailEntity> details = detailRepository.findByTicketId(ticket.getId());
        List<MaintenanceDetailResult> detailResults = details.stream().map(d -> {
            String devName = "N/A";
            if (d.getDeviceId() != null && d.getDeviceId() > 0) {
                Device device = deviceRepository.findById(d.getDeviceId()).orElse(null);
                if (device != null) devName = device.getName();
            }
            return new MaintenanceDetailResult(
                    d.getId(), d.getTicketId(), d.getDeviceId(), devName,
                    d.getQuantityUsed(), d.getUnitPriceSnapshot(),
                    Arrays.asList(d.getAfterImages()), d.getNote());
        }).collect(Collectors.toList());

        return new MaintenanceTicketResult(
                ticket.getId(), motelId, ticket.getRoomId(), roomNumber,
                ticket.getReportedBy(), reporterName,
                ticket.getAssignedTo(), technicianName,
                ticket.getCategory(), ticket.getDescription(),
                Arrays.asList(ticket.getBeforeImages()),
                ticket.getStatus(), ticket.getPriority(), detailResults,
                ticket.getCreatedAt(), ticket.getUpdatedAt(), ticket.getCompletedAt());
    }
}

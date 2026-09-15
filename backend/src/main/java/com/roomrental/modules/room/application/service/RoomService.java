package com.roomrental.modules.room.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.room.application.dto.RoomCreateCommand;
import com.roomrental.modules.room.application.dto.RoomResult;
import com.roomrental.modules.room.application.dto.RoomUpdateCommand;
import com.roomrental.modules.room.application.event.RoomCreatedEvent;
import com.roomrental.modules.room.application.event.RoomDeletedEvent;
import com.roomrental.modules.room.application.event.RoomStatusUpdatedEvent;
import com.roomrental.modules.room.application.event.RoomUpdatedEvent;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.roomrental.common.util.HashidsCodec;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Application service for Room management (UC26-UC31).
 */
@Service
public class RoomService {

    private final RoomRepository roomRepository;
    private final MotelRepository motelRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final HashidsCodec hashidsCodec;

    public RoomService(RoomRepository roomRepository, MotelRepository motelRepository, ApplicationEventPublisher eventPublisher, HashidsCodec hashidsCodec) {
        this.roomRepository = roomRepository;
        this.motelRepository = motelRepository;
        this.eventPublisher = eventPublisher;
        this.hashidsCodec = hashidsCodec;
    }

    /**
     * UC26: Create a new room in a motel.
     */
    @Transactional(rollbackFor = Exception.class)
    public RoomResult create(Long motelId, RoomCreateCommand command) {
        return createInternal(motelId, command);
    }

    @Transactional(rollbackFor = Exception.class)
    public List<RoomResult> createBulk(Long motelId, List<RoomCreateCommand> commands) {
        if (commands == null || commands.isEmpty()) {
            throw BaseException.badRequest("rooms: required");
        }

        List<RoomResult> results = new ArrayList<>();
        for (RoomCreateCommand command : commands) {
            results.add(createInternal(motelId, command));
        }
        return results;
    }

    private RoomResult createInternal(Long motelId, RoomCreateCommand command) {
        Motel motel = requireMotel(motelId);

        if (roomRepository.existsByMotelIdAndRoomNumber(motelId, command.roomNumber())) {
            throw BaseException.conflict("Room number '" + command.roomNumber() + "' already exists in this motel");
        }
        if (command.floor() > motel.getTotalFloors()) {
            throw BaseException.badRequest("Floor " + command.floor() + " exceeds motel total floors (" + motel.getTotalFloors() + ")");
        }

        Room room = new Room();
        room.setMotelId(motelId);
        room.setRoomNumber(command.roomNumber());
        room.setFloor(command.floor());
        room.setArea(command.area());
        room.setBasePrice(command.basePrice());
        room.setStatus(RoomStatus.EMPTY);
        room.setCurrentResidentsCount(0);
        room.setDescription(command.description());

        RoomResult result = toResult(roomRepository.save(room));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new RoomCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), result.roomNumber()));
        return result;
    }

    /**
     * UC27: List rooms of a motel with pagination.
     */
    @Transactional(readOnly = true)
    public PageResponse<RoomResult> list(Long motelId, Pageable pageable) {
        requireMotel(motelId);
        return PageResponse.from(roomRepository.findByMotelId(motelId, pageable), this::toResult);
    }

    /**
     * UC28: Get room detail.
     */
    @Transactional(readOnly = true)
    public RoomResult get(Long motelId, Long roomId) {
        return toResult(findRoom(motelId, roomId));
    }

    /**
     * UC29: Update room info (partial update).
     */
    @Transactional(rollbackFor = Exception.class)
    public RoomResult update(Long motelId, Long roomId, RoomUpdateCommand command) {
        Room room = findRoom(motelId, roomId);
        String oldNumber = room.getRoomNumber();

        if (command.roomNumber() != null && !command.roomNumber().isBlank()) {
            if (!command.roomNumber().equals(room.getRoomNumber())
                    && roomRepository.existsByMotelIdAndRoomNumber(motelId, command.roomNumber())) {
                throw BaseException.conflict("Room number '" + command.roomNumber() + "' already exists");
            }
            room.setRoomNumber(command.roomNumber());
        }
        if (command.floor() != null) {
            room.setFloor(command.floor());
        }
        if (command.area() != null) {
            room.setArea(command.area());
        }
        if (command.basePrice() != null) {
            room.setBasePrice(command.basePrice());
        }
        if (command.description() != null) {
            room.setDescription(command.description());
        }

        RoomResult result = toResult(roomRepository.save(room));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new RoomUpdatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldNumber, result.roomNumber()));
        return result;
    }

    /**
     * UC30: Update room status.
     */
    @Transactional(rollbackFor = Exception.class)
    public RoomResult updateStatus(Long motelId, Long roomId, String newStatus) {
        Room room = findRoom(motelId, roomId);
        String oldStatus = room.getStatus().name();
        RoomStatus target = parseStatus(newStatus);
        room.setStatus(target);

        RoomResult result = toResult(roomRepository.save(room));
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new RoomStatusUpdatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldStatus, result.status()));
        return result;
    }

    /**
     * UC31: Soft-delete room.
     * Only allowed when room is EMPTY.
     */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long motelId, Long roomId) {
        Room room = findRoom(motelId, roomId);
        if (room.getStatus() != RoomStatus.EMPTY) {
            throw new BaseException(HttpStatus.CONFLICT, "ROOM_NOT_EMPTY",
                    "Can only delete rooms with EMPTY status. Current status: " + room.getStatus());
        }
        room.setDeleted(true);
        roomRepository.save(room);

        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new RoomDeletedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                roomId, room.getRoomNumber()));
    }

    // ── Private helpers ──────────────────────────────────────────────

    private Motel requireMotel(Long motelId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return motelRepository.findByIdAndTenantId(motelId, tenantId)
                .orElseThrow(() -> BaseException.notFound("Motel", motelId));
    }

    private Room findRoom(Long motelId, Long roomId) {
        requireMotel(motelId); // ensure tenant ownership
        return roomRepository.findByIdAndMotelId(roomId, motelId)
                .orElseThrow(() -> BaseException.notFound("Room", roomId));
    }

    private RoomStatus parseStatus(String status) {
        try {
            return RoomStatus.valueOf(status);
        } catch (IllegalArgumentException e) {
            throw BaseException.badRequest("Invalid room status: " + status);
        }
    }

    private RoomResult toResult(Room room) {
        return new RoomResult(
                room.getId(), room.getMotelId(), room.getRoomNumber(),
                room.getFloor(), room.getArea(), room.getBasePrice(),
                room.getStatus().name(), room.getCurrentResidentsCount(),
                room.getDescription(), hashidsCodec.encode(room.getId())
        );
    }
}

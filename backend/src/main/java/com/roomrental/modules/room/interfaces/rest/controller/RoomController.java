package com.roomrental.modules.room.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.room.application.dto.RoomCreateCommand;
import com.roomrental.modules.room.application.dto.RoomResult;
import com.roomrental.modules.room.application.dto.RoomUpdateCommand;
import com.roomrental.modules.room.application.service.RoomService;
import com.roomrental.modules.room.interfaces.rest.dto.RoomCreateRequest;
import com.roomrental.modules.room.interfaces.rest.dto.RoomBulkCreateRequest;
import com.roomrental.modules.room.interfaces.rest.dto.RoomStatusRequest;
import com.roomrental.modules.room.interfaces.rest.dto.RoomUpdateRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.roomrental.common.util.HashidsCodec;
import com.roomrental.common.exception.BaseException;

import java.util.List;

/**
 * REST controller for Room management (UC26-UC31).
 */
@RestController
@RequestMapping("/api/motels/{motelId}/rooms")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Room", description = "Room management within a motel")
public class RoomController {

    private final RoomService roomService;
    private final HashidsCodec hashidsCodec;

    public RoomController(RoomService roomService, HashidsCodec hashidsCodec) {
        this.roomService = roomService;
        this.hashidsCodec = hashidsCodec;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Create room (UC26)")
    public ResponseEntity<ApiResponse<RoomResult>> create(
            @PathVariable Long motelId,
            @Valid @RequestBody RoomCreateRequest body) {
        RoomResult result = roomService.create(motelId, new RoomCreateCommand(
                body.roomNumber(), body.floor(), body.area(), body.basePrice(), body.description()
        ));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Room created"));
    }

        @PostMapping("/bulk")
        @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
        @Operation(summary = "Bulk create rooms")
        public ResponseEntity<ApiResponse<List<RoomResult>>> createBulk(
            @PathVariable Long motelId,
            @Valid @RequestBody RoomBulkCreateRequest body) {
        List<RoomResult> results = roomService.createBulk(motelId, body.rooms().stream()
            .map(item -> new RoomCreateCommand(
                item.roomNumber(), item.floor(), item.area(), item.basePrice(), item.description()))
            .toList());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(results, "Rooms created"));
        }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "List rooms (UC27)")
    public ResponseEntity<ApiResponse<PageResponse<RoomResult>>> list(
            @PathVariable Long motelId,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(roomService.list(motelId, pageable)));
    }

    @GetMapping("/{roomId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "Get room detail (UC28)")
    public ResponseEntity<ApiResponse<RoomResult>> get(
            @PathVariable Long motelId, @PathVariable String roomId) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) throw BaseException.badRequest("roomId: invalid");
        return ResponseEntity.ok(ApiResponse.ok(roomService.get(motelId, decoded)));
    }

    @PatchMapping("/{roomId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update room (UC29)")
        public ResponseEntity<ApiResponse<RoomResult>> update(
            @PathVariable Long motelId, @PathVariable String roomId,
            @RequestBody RoomUpdateRequest body) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) throw BaseException.badRequest("roomId: invalid");
        RoomResult result = roomService.update(motelId, decoded, new RoomUpdateCommand(
            body.roomNumber(), body.floor(), body.area(), body.basePrice(), null, body.description()
        ));
        return ResponseEntity.ok(ApiResponse.ok(result, "Room updated"));
        }

    @PatchMapping("/{roomId}/status")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update room status (UC30)")
    public ResponseEntity<ApiResponse<RoomResult>> updateStatus(
            @PathVariable Long motelId, @PathVariable String roomId,
            @Valid @RequestBody RoomStatusRequest body) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) throw BaseException.badRequest("roomId: invalid");
        return ResponseEntity.ok(ApiResponse.ok(roomService.updateStatus(motelId, decoded, body.status())));
    }

    @DeleteMapping("/{roomId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Delete room (UC31)")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long motelId, @PathVariable String roomId) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) throw BaseException.badRequest("roomId: invalid");
        roomService.delete(motelId, decoded);
        return ResponseEntity.ok(ApiResponse.ok("Room deleted"));
    }
}

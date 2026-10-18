package com.roomrental.modules.device.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.device.application.dto.*;
import com.roomrental.modules.device.application.service.DeviceService;
import com.roomrental.modules.device.interfaces.rest.dto.*;
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

import java.util.List;

@RestController
@RequestMapping("/api/motels/{motelId}")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Device", description = "Device/equipment management")
public class DeviceController {

    private final DeviceService deviceService;

    public DeviceController(DeviceService deviceService) { this.deviceService = deviceService; }

    @PostMapping("/devices")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Create device (UC40)")
    public ResponseEntity<ApiResponse<DeviceResult>> create(
            @PathVariable Long motelId, @Valid @RequestBody DeviceCreateRequest body) {
        DeviceResult result = deviceService.create(motelId, new DeviceCreateCommand(
                body.name(), body.brand(), body.purchasePrice(), body.purchaseDate(), body.totalQuantity()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Device created"));
    }

    @GetMapping("/devices")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN','RESIDENT')")
    @Operation(summary = "List devices (UC41)")
    public ResponseEntity<ApiResponse<PageResponse<DeviceResult>>> list(
            @PathVariable Long motelId,
            @RequestParam(value = "includeDeleted", defaultValue = "false") boolean includeDeleted,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.list(motelId, includeDeleted, pageable)));
    }

    @GetMapping("/devices/{deviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "Get device detail (UC42)")
    public ResponseEntity<ApiResponse<DeviceResult>> get(
            @PathVariable Long motelId, @PathVariable Long deviceId) {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.get(motelId, deviceId)));
    }

    @PatchMapping("/devices/{deviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update device (UC44)")
    public ResponseEntity<ApiResponse<DeviceResult>> update(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @RequestBody DeviceUpdateRequest body) {
        DeviceResult result = deviceService.update(motelId, deviceId, new DeviceUpdateCommand(
                body.name(), body.brand(), body.purchasePrice(), body.purchaseDate()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Device updated"));
    }

    @PostMapping("/devices/{deviceId}/import")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Import more devices to stock")
    public ResponseEntity<ApiResponse<DeviceResult>> importStock(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @Valid @RequestBody DeviceImportRequest body) {
        DeviceResult result = deviceService.importStock(motelId, deviceId, new DeviceImportCommand(body.quantity(), body.note()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Devices imported to stock"));
    }

    @PostMapping("/devices/{deviceId}/dispose")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Dispose devices from stock")
    public ResponseEntity<ApiResponse<DeviceResult>> disposeStock(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @Valid @RequestBody DeviceDisposeRequest body) {
        DeviceResult result = deviceService.disposeStock(motelId, deviceId, new DeviceDisposeCommand(body.quantity(), body.reason()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Devices disposed from stock"));
    }

    @DeleteMapping("/devices/{deviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Delete device (UC45)")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long motelId, @PathVariable Long deviceId) {
        deviceService.delete(motelId, deviceId);
        return ResponseEntity.ok(ApiResponse.ok("Device deleted"));
    }

    @GetMapping("/rooms/{roomId}/devices")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "Get devices assigned to a room (UC43)")
    public ResponseEntity<ApiResponse<List<DeviceUsageResult>>> getDevicesByRoom(
            @PathVariable Long motelId, @PathVariable Long roomId) {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.getDevicesByRoom(motelId, roomId)));
    }

    @PostMapping("/devices/{deviceId}/assign")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Assign device to room (UC46)")
    public ResponseEntity<ApiResponse<DeviceUsageResult>> assignDevice(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @Valid @RequestBody DeviceAssignRequest body) {
        DeviceUsageResult result = deviceService.assignDeviceToRoom(motelId, deviceId, new DeviceAssignCommand(
                body.roomId(), body.assignedQuantity(), body.condition(), body.note()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Device assigned to room"));
    }

    @PostMapping("/devices/{deviceId}/recall")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Recall device from room (UC47)")
    public ResponseEntity<ApiResponse<Void>> recallDevice(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @RequestParam Long roomId,
            @RequestBody(required = false) DeviceRecallRequest body) {
        Integer quantity = body != null ? body.quantity() : null;
        String note = body != null ? body.note() : null;
        deviceService.recallDeviceFromRoom(motelId, deviceId, roomId, new DeviceRecallCommand(quantity, note));
        return ResponseEntity.ok(ApiResponse.ok("Device recalled from room"));
    }

    @GetMapping("/devices/{deviceId}/movement-logs")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "Get movement history of a device")
    public ResponseEntity<ApiResponse<List<DeviceMovementLogResult>>> getMovementLogs(
            @PathVariable Long motelId, @PathVariable Long deviceId) {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.getMovementLogs(motelId, deviceId)));
    }

    @PostMapping("/devices/{deviceId}/send-to-repair")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Send devices to repair (UC85)")
    public ResponseEntity<ApiResponse<DeviceResult>> sendToRepair(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @Valid @RequestBody DeviceSendToRepairRequest body) {
        DeviceResult result = deviceService.sendToRepair(motelId, deviceId,
                new DeviceSendToRepairCommand(body.quantity(), body.note()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Devices sent to repair"));
    }

    @PostMapping("/devices/{deviceId}/finish-repair")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Finish repair of devices (UC86)")
    public ResponseEntity<ApiResponse<DeviceResult>> finishRepair(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @Valid @RequestBody DeviceFinishRepairRequest body) {
        DeviceResult result = deviceService.finishRepair(motelId, deviceId,
                new DeviceFinishRepairCommand(body.quantity(), body.note()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Devices repair finished"));
    }


}

package com.roomrental.modules.device.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.device.application.dto.DeviceCreateCommand;
import com.roomrental.modules.device.application.dto.DeviceResult;
import com.roomrental.modules.device.application.dto.DeviceUpdateCommand;
import com.roomrental.modules.device.application.service.DeviceService;
import com.roomrental.modules.device.interfaces.rest.dto.DeviceCreateRequest;
import com.roomrental.modules.device.interfaces.rest.dto.DeviceUpdateRequest;
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

@RestController
@RequestMapping("/api/motels/{motelId}/devices")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Device", description = "Device/equipment management")
public class DeviceController {

    private final DeviceService deviceService;

    public DeviceController(DeviceService deviceService) { this.deviceService = deviceService; }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Create device (UC40)")
    public ResponseEntity<ApiResponse<DeviceResult>> create(
            @PathVariable Long motelId, @Valid @RequestBody DeviceCreateRequest body) {
        DeviceResult result = deviceService.create(motelId, new DeviceCreateCommand(
                body.name(), body.brand(), body.purchasePrice(), body.purchaseDate()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Device created"));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "List devices (UC41)")
    public ResponseEntity<ApiResponse<PageResponse<DeviceResult>>> list(
            @PathVariable Long motelId, @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.list(motelId, pageable)));
    }

    @GetMapping("/{deviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "Get device detail (UC42)")
    public ResponseEntity<ApiResponse<DeviceResult>> get(
            @PathVariable Long motelId, @PathVariable Long deviceId) {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.get(motelId, deviceId)));
    }

    @PatchMapping("/{deviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update device (UC44)")
    public ResponseEntity<ApiResponse<DeviceResult>> update(
            @PathVariable Long motelId, @PathVariable Long deviceId,
            @RequestBody DeviceUpdateRequest body) {
        DeviceResult result = deviceService.update(motelId, deviceId, new DeviceUpdateCommand(
                body.name(), body.brand(), body.purchasePrice(), body.purchaseDate(), body.status()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Device updated"));
    }

    @DeleteMapping("/{deviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Delete device (UC45)")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long motelId, @PathVariable Long deviceId) {
        deviceService.delete(motelId, deviceId);
        return ResponseEntity.ok(ApiResponse.ok("Device deleted"));
    }
}

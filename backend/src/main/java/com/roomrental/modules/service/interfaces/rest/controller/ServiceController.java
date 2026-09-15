package com.roomrental.modules.service.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.service.application.dto.ServiceAssignCommand;
import com.roomrental.modules.service.application.dto.ServiceCreateCommand;
import com.roomrental.modules.service.application.dto.ServiceResult;
import com.roomrental.modules.service.application.dto.ServiceTierPricingCommand;
import com.roomrental.modules.service.application.dto.ServiceUpdateCommand;
import com.roomrental.modules.service.application.service.RentalServiceService;
import com.roomrental.modules.service.interfaces.rest.dto.ServiceAssignRequest;
import com.roomrental.modules.service.interfaces.rest.dto.ServiceCreateRequest;
import com.roomrental.modules.service.interfaces.rest.dto.ServiceUpdateRequest;
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

@RestController
@RequestMapping("/api/motels/{motelId}/services")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Service", description = "Rental service management")
public class ServiceController {

    private final RentalServiceService svc;
    private final HashidsCodec hashidsCodec;

    public ServiceController(RentalServiceService svc, HashidsCodec hashidsCodec) { this.svc = svc; this.hashidsCodec = hashidsCodec; }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Create service (UC32)")
    public ResponseEntity<ApiResponse<ServiceResult>> create(
            @PathVariable Long motelId, @Valid @RequestBody ServiceCreateRequest body) {
        ServiceResult result = svc.create(motelId, new ServiceCreateCommand(
            body.name(), body.chargeType(), body.unit(), body.mandatory(),
            body.basePrice(), body.pricingTiers() == null ? null : body.pricingTiers().stream()
                .map(item -> new ServiceTierPricingCommand(item.tierStart(), item.tierEnd(), item.pricePerUnit()))
                .toList()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Service created"));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','TECHNICIAN')")
    @Operation(summary = "List services (UC33)")
    public ResponseEntity<ApiResponse<PageResponse<ServiceResult>>> list(
            @PathVariable Long motelId, @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(svc.list(motelId, pageable)));
    }

    @GetMapping("/{serviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Get service detail (UC34)")
    public ResponseEntity<ApiResponse<ServiceResult>> get(
            @PathVariable Long motelId, @PathVariable Long serviceId) {
        return ResponseEntity.ok(ApiResponse.ok(svc.get(motelId, serviceId)));
    }

    @PatchMapping("/{serviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update service (UC35)")
    public ResponseEntity<ApiResponse<ServiceResult>> update(
            @PathVariable Long motelId, @PathVariable Long serviceId,
            @RequestBody ServiceUpdateRequest body) {
        ServiceResult result = svc.update(motelId, serviceId, new ServiceUpdateCommand(
            body.name(), body.chargeType(), body.unit(), body.mandatory(),
            body.basePrice(), body.pricingTiers() == null ? null : body.pricingTiers().stream()
                .map(item -> new ServiceTierPricingCommand(item.tierStart(), item.tierEnd(), item.pricePerUnit()))
                .toList()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Service updated"));
    }

    @DeleteMapping("/{serviceId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Delete service (UC36)")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long motelId, @PathVariable Long serviceId) {
        svc.delete(motelId, serviceId);
        return ResponseEntity.ok(ApiResponse.ok("Service deleted"));
    }

    @PostMapping("/{serviceId}/assign-to-rooms")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Assign service to multiple rooms (UC37)")
    public ResponseEntity<ApiResponse<Void>> assignToRooms(
            @PathVariable Long motelId, @PathVariable Long serviceId,
            @Valid @RequestBody ServiceAssignRequest body) {
        svc.assignToRooms(motelId, serviceId, new ServiceAssignCommand(
            body.roomIds().stream().map(id -> new ServiceAssignCommand.RoomAssignInput(id, 1, null)).toList()
        ));
        return ResponseEntity.ok(ApiResponse.ok("Service assigned to rooms"));
    }

    /**
     * UC37+: Get services currently assigned to a specific room.
     */
    @GetMapping("/by-room/{roomId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','RESIDENT')")
    @Operation(summary = "Get services assigned to a room (UC37+)")
    public ResponseEntity<ApiResponse<List<ServiceResult>>> listByRoom(
            @PathVariable Long motelId, @PathVariable String roomId) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) {
            try {
                decoded = Long.parseLong(roomId);
            } catch (NumberFormatException e) {
                throw BaseException.badRequest("roomId: invalid");
            }
        }
        return ResponseEntity.ok(ApiResponse.ok(svc.listByRoom(motelId, decoded)));
    }

}

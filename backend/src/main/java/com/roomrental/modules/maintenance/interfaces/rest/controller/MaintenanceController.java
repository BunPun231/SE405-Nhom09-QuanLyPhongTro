package com.roomrental.modules.maintenance.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.maintenance.application.dto.*;
import com.roomrental.modules.maintenance.application.service.MaintenanceService;
import com.roomrental.modules.maintenance.interfaces.rest.dto.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/maintenance")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Maintenance", description = "Maintenance & ticket management")
public class MaintenanceController {

    private final MaintenanceService maintenanceService;

    public MaintenanceController(MaintenanceService maintenanceService) {
        this.maintenanceService = maintenanceService;
    }

    @PostMapping(value = "/tickets", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('RESIDENT','MANAGER','ADMIN')")
    @Operation(summary = "Report maintenance ticket with images uploaded via Backend Cloudinary (UC70)")
    public ResponseEntity<ApiResponse<MaintenanceTicketResult>> createTicket(
            @RequestParam("roomId") Long roomId,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam("description") String description,
            @RequestParam(value = "priority", required = false) String priority,
            @RequestParam(value = "files", required = false) List<MultipartFile> files) {
        CreateTicketCommand command = new CreateTicketCommand(roomId, category, description, priority, files);
        MaintenanceTicketResult result = maintenanceService.createTicket(command);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Ticket created successfully"));
    }

    @GetMapping("/tickets/{ticketId}")
    @PreAuthorize("hasAnyRole('RESIDENT','TECHNICIAN','MANAGER','ADMIN')")
    @Operation(summary = "Get ticket detail")
    public ResponseEntity<ApiResponse<MaintenanceTicketResult>> getTicketDetail(@PathVariable Long ticketId) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.getTicketDetail(ticketId)));
    }

    @PostMapping("/tickets/{ticketId}/assign")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Assign technician to ticket (UC72)")
    public ResponseEntity<ApiResponse<MaintenanceTicketResult>> assignTicket(
            @PathVariable Long ticketId, @RequestBody AssignTicketRequest body) {
        MaintenanceTicketResult result = maintenanceService.assignTicket(
                ticketId, new AssignTicketCommand(body.technicianId()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Technician assigned"));
    }

    @PostMapping(value = "/tickets/{ticketId}/complete", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('TECHNICIAN','MANAGER','ADMIN')")
    @Operation(summary = "Complete ticket with after images uploaded via Backend Cloudinary (UC74)")
    public ResponseEntity<ApiResponse<MaintenanceTicketResult>> completeTicket(
            @PathVariable Long ticketId,
            @RequestParam(value = "note", required = false) String note,
            @RequestParam(value = "usedDeviceId", required = false) Long usedDeviceId,
            @RequestParam(value = "usedQuantity", required = false) Integer usedQuantity,
            @RequestParam(value = "files", required = false) List<MultipartFile> files) {
        List<UsedDeviceItem> usedDevices = usedDeviceId != null
                ? List.of(new UsedDeviceItem(usedDeviceId, usedQuantity != null ? usedQuantity : 1, null))
                : List.of();
        CompleteTicketCommand command = new CompleteTicketCommand(usedDevices, note, files);
        MaintenanceTicketResult result = maintenanceService.completeTicket(ticketId, command);
        return ResponseEntity.ok(ApiResponse.ok(result, "Ticket completed successfully"));
    }
    @PostMapping("/tickets/{ticketId}/cancel")
    @PreAuthorize("hasAnyRole('RESIDENT','MANAGER','ADMIN')")
    @Operation(summary = "Cancel maintenance ticket")
    public ResponseEntity<ApiResponse<MaintenanceTicketResult>> cancelTicket(@PathVariable Long ticketId) {
        MaintenanceTicketResult result = maintenanceService.cancelTicket(ticketId);
        return ResponseEntity.ok(ApiResponse.ok(result, "Ticket cancelled successfully"));
    }

    @PutMapping("/tickets/{ticketId}")
    @PreAuthorize("hasAnyRole('RESIDENT','MANAGER','ADMIN')")
    @Operation(summary = "Update maintenance ticket details")
    public ResponseEntity<ApiResponse<MaintenanceTicketResult>> updateTicket(
            @PathVariable Long ticketId, @RequestBody UpdateTicketRequest body) {
        UpdateTicketCommand command = new UpdateTicketCommand(
                body.category(), body.description(), body.priority());
        MaintenanceTicketResult result = maintenanceService.updateTicket(ticketId, command);
        return ResponseEntity.ok(ApiResponse.ok(result, "Ticket updated successfully"));
    }


    @GetMapping("/motels/{motelId}/tickets")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "List tickets for a motel (Manager)")
    public ResponseEntity<ApiResponse<PageResponse<MaintenanceTicketResult>>> listForManager(
            @PathVariable Long motelId, @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.listForManager(motelId, pageable)));
    }

    @GetMapping("/my-tasks")
    @PreAuthorize("hasRole('TECHNICIAN')")
    @Operation(summary = "List assigned tickets for current Technician")
    public ResponseEntity<ApiResponse<PageResponse<MaintenanceTicketResult>>> listMyTasks(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.listForTechnician(pageable)));
    }

    @GetMapping("/my-tickets")
    @PreAuthorize("hasRole('RESIDENT')")
    @Operation(summary = "List reported tickets for current Resident")
    public ResponseEntity<ApiResponse<PageResponse<MaintenanceTicketResult>>> listMyTickets(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.listForTenant(pageable)));
    }
}

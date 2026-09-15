package com.roomrental.modules.technician.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.technician.application.dto.TechnicianCreateCommand;
import com.roomrental.modules.technician.application.dto.TechnicianResult;
import com.roomrental.modules.technician.application.service.TechnicianService;
import com.roomrental.modules.technician.interfaces.rest.dto.LockRequest;
import com.roomrental.modules.technician.interfaces.rest.dto.TechnicianCreateRequest;
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

import java.util.UUID;

@RestController
@RequestMapping("/api/technicians")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Technician", description = "Technician management")
public class TechnicianController {

    private final TechnicianService technicianService;

    public TechnicianController(TechnicianService technicianService) {
        this.technicianService = technicianService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Add technician (UC56)")
    public ResponseEntity<ApiResponse<TechnicianResult>> create(
            @Valid @RequestBody TechnicianCreateRequest body) {
        TechnicianResult result = technicianService.create(new TechnicianCreateCommand(
                body.phone(), body.email(), body.fullName(), body.expertise(), body.assignedMotelIds()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Technician created"));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "List technicians (UC57)")
    public ResponseEntity<ApiResponse<PageResponse<TechnicianResult>>> list(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(technicianService.list(pageable)));
    }

    @GetMapping("/{techId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Get technician detail (UC58)")
    public ResponseEntity<ApiResponse<TechnicianResult>> get(@PathVariable UUID techId) {
        return ResponseEntity.ok(ApiResponse.ok(technicianService.get(techId)));
    }

    @PostMapping("/{techId}/lock")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Lock technician (UC60)")
    public ResponseEntity<ApiResponse<Void>> lock(
            @PathVariable UUID techId, @RequestBody(required = false) LockRequest body) {
        technicianService.lock(techId, body != null ? body.reason() : null);
        return ResponseEntity.ok(ApiResponse.ok("Technician locked"));
    }

    @PostMapping("/{techId}/reset-password")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Reset technician password (UC62)")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@PathVariable UUID techId) {
        technicianService.resetPassword(techId);
        return ResponseEntity.ok(ApiResponse.ok("Password reset to default"));
    }
}

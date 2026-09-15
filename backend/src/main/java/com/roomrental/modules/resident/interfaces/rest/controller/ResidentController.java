package com.roomrental.modules.resident.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.resident.application.dto.ResidentCreateCommand;
import com.roomrental.modules.resident.application.dto.ResidentResult;
import com.roomrental.modules.resident.application.dto.ResidentUpdateCommand;
import com.roomrental.modules.resident.application.service.ResidentService;
import com.roomrental.modules.resident.interfaces.rest.dto.ResidentCreateRequest;
import com.roomrental.modules.resident.interfaces.rest.dto.ResidentUpdateRequest;
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
@RequestMapping("/api/residents")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Resident", description = "Resident (tenant/renter) management")
public class ResidentController {

    private final ResidentService residentService;

    public ResidentController(ResidentService residentService) {
        this.residentService = residentService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Add resident (UC49)")
    public ResponseEntity<ApiResponse<ResidentResult>> create(@Valid @RequestBody ResidentCreateRequest body) {
        ResidentResult result = residentService.create(new ResidentCreateCommand(
                body.phone(), body.email(), body.fullName(),
                body.idCardNumber(), body.idCardFrontUrl(), body.idCardBackUrl()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Resident created"));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "List residents (UC50)")
    public ResponseEntity<ApiResponse<PageResponse<ResidentResult>>> list(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(residentService.list(pageable)));
    }

    @GetMapping("/{residentId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Get resident detail (UC51)")
    public ResponseEntity<ApiResponse<ResidentResult>> get(@PathVariable UUID residentId) {
        return ResponseEntity.ok(ApiResponse.ok(residentService.get(residentId)));
    }

    @PostMapping("/{residentId}/deactivate")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Deactivate resident (UC54)")
    public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable UUID residentId) {
        residentService.deactivate(residentId);
        return ResponseEntity.ok(ApiResponse.ok("Resident deactivated"));
    }

    @PatchMapping("/{residentId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update resident profile (UC53)")
    public ResponseEntity<ApiResponse<ResidentResult>> update(
            @PathVariable UUID residentId,
            @RequestBody ResidentUpdateRequest body) {
        ResidentResult result = residentService.update(new ResidentUpdateCommand(
                residentId, body.email(), body.fullName(),
                body.idCardNumber(), body.idCardFrontUrl(), body.idCardBackUrl()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Resident updated"));
    }
}

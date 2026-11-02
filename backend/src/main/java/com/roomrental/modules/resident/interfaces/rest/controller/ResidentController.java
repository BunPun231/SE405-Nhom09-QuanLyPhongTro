package com.roomrental.modules.resident.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.resident.application.dto.ResidentCreateCommand;
import com.roomrental.modules.resident.application.dto.ResidentResult;
import com.roomrental.modules.resident.application.dto.ResidentUpdateCommand;
import com.roomrental.modules.resident.application.dto.ResidentViews;
import com.roomrental.modules.resident.application.service.ResidentQueryService;
import com.roomrental.modules.resident.application.service.ResidentService;
import com.roomrental.modules.resident.interfaces.rest.dto.ResidentCreateRequest;
import com.roomrental.modules.resident.interfaces.rest.dto.ResidentUpdateRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/residents")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Resident", description = "Resident (tenant/renter) management")
public class ResidentController {

    private final ResidentService residentService;
    private final ResidentQueryService queryService;

    public ResidentController(ResidentService residentService, ResidentQueryService queryService) {
        this.residentService = residentService;
        this.queryService = queryService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Add resident (UC49)")
    public ResponseEntity<ApiResponse<ResidentResult>> create(@Valid @RequestBody ResidentCreateRequest body) {
        ResidentResult result = residentService.create(new ResidentCreateCommand(
                body.phone(), body.email(), body.fullName(),
                body.idCardNumber(), body.idCardFrontUrl(), body.idCardBackUrl(),
                body.dateOfBirth(), body.gender(), body.notes(), body.avatarUrl(), body.contractId()));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Resident created"));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "List residents (UC50)")
    public ResponseEntity<ApiResponse<PageResponse<ResidentResult>>> list(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(residentService.list(pageable)));
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Search residents with room, contract and debt status (UC50)")
    public ResponseEntity<ApiResponse<PageResponse<ResidentViews.Summary>>> search(
            @RequestParam(required = false, defaultValue = "") String q,
            @RequestParam(required = false, defaultValue = "ALL") String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(queryService.search(q, status, page, size)));
    }

    @GetMapping("/history")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Historical tenants who moved out, filter by move-out date (UC52)")
    public ResponseEntity<ApiResponse<PageResponse<ResidentViews.History>>> history(
            @RequestParam(required = false, defaultValue = "") String q,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(ApiResponse.ok(queryService.history(q, from, to, page, size)));
    }

    @GetMapping("/linkable-contracts")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Open contracts a new resident can be linked to (UC49)")
    public ResponseEntity<ApiResponse<java.util.List<ResidentViews.LinkableContract>>> linkableContracts() {
        return ResponseEntity.ok(ApiResponse.ok(queryService.linkableContracts()));
    }

    @GetMapping("/{residentId}/overview")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Resident detail with contracts, payments, maintenance and change history (UC51)")
    public ResponseEntity<ApiResponse<ResidentViews.Overview>> overview(@PathVariable UUID residentId) {
        return ResponseEntity.ok(ApiResponse.ok(queryService.overview(residentService.get(residentId))));
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
            @Valid @RequestBody ResidentUpdateRequest body) {
        ResidentResult result = residentService.update(new ResidentUpdateCommand(
                residentId, body.email(), body.fullName(),
                body.idCardNumber(), body.idCardFrontUrl(), body.idCardBackUrl(),
                body.phone(), body.notes(), body.dateOfBirth(), body.gender(), body.avatarUrl()));
        return ResponseEntity.ok(ApiResponse.ok(result, "Resident updated"));
    }
}

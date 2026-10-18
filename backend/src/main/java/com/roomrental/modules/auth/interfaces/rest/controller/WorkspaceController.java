package com.roomrental.modules.auth.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.auth.application.dto.WorkspaceConfigDto;
import com.roomrental.modules.auth.application.service.WorkspaceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/workspace")
@Tag(name = "Workspace Customization", description = "Endpoints for customizing workspace features and module visibility (UC17)")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
@RequiredArgsConstructor
public class WorkspaceController {

    private final WorkspaceService workspaceService;

    @GetMapping("/config")
    @Operation(summary = "Get workspace module configuration (UC17)")
    public ResponseEntity<ApiResponse<WorkspaceConfigDto>> getWorkspaceConfig() {
        UUID tenantId = SecurityUtils.requireTenantId();
        WorkspaceConfigDto config = workspaceService.getWorkspaceConfig(tenantId);
        return ResponseEntity.ok(ApiResponse.ok(config));
    }

    @PutMapping("/config")
    @Operation(summary = "Update workspace module configuration (UC17)")
    public ResponseEntity<ApiResponse<WorkspaceConfigDto>> updateWorkspaceConfig(
            @Valid @RequestBody WorkspaceConfigDto body
    ) {
        UUID tenantId = SecurityUtils.requireTenantId();
        WorkspaceConfigDto updated = workspaceService.updateWorkspaceConfig(tenantId, body);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Workspace configuration updated successfully"));
    }
}

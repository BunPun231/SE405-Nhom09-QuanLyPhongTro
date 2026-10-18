package com.roomrental.modules.auth.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.auth.application.dto.ManagerResponse;
import com.roomrental.modules.auth.application.dto.UserProfileResponse;
import com.roomrental.modules.auth.application.service.UserService;
import com.roomrental.modules.auth.domain.model.UserStatus;
import com.roomrental.modules.auth.interfaces.rest.dto.UpdateUserStatusRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/managers")
@Tag(name = "Admin Manager Management", description = "Admin endpoints for managing motel managers/landlords")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminManagerController {

    private final UserService userService;

    @GetMapping
    @Operation(summary = "Get list of managers (UC - View Manager List)")
    public ResponseEntity<ApiResponse<PageResponse<ManagerResponse>>> getManagers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ManagerResponse> result = userService.getManagers(search, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Lock or unlock a manager account (UC - Lock/Unlock Manager Account)")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateManagerStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserStatusRequest body
    ) {
        UserProfileResponse response = userService.updateManagerStatus(id, body.status(), body.lockReason());
        return ResponseEntity.ok(ApiResponse.ok(response, "Manager status updated successfully"));
    }
}

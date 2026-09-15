package com.roomrental.modules.motel.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.motel.application.dto.MotelResult;
import com.roomrental.modules.motel.application.dto.MotelUpsertCommand;
import com.roomrental.modules.motel.application.service.MotelService;
import com.roomrental.modules.motel.interfaces.rest.dto.MotelPatchRequestBody;
import com.roomrental.modules.motel.interfaces.rest.dto.MotelUpsertRequestBody;
import com.roomrental.modules.motel.interfaces.rest.dto.PaymentConfigRequestBody;
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

/**
 * REST controller for Motel management (UC20-UC25).
 */
@RestController
@RequestMapping("/api/motels")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Motel", description = "Motel (boarding house) management")
public class MotelController {

    private final MotelService motelService;

    public MotelController(MotelService motelService) {
        this.motelService = motelService;
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Create motel (UC20)")
    public ResponseEntity<ApiResponse<MotelResult>> create(@Valid @RequestBody MotelUpsertRequestBody body) {
        MotelResult result = motelService.create(toCommand(body));
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(result, "Motel created"));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "List motels (UC21)")
    public ResponseEntity<ApiResponse<PageResponse<MotelResult>>> list(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(motelService.list(pageable)));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Get motel detail (UC22)")
    public ResponseEntity<ApiResponse<MotelResult>> get(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(motelService.get(id)));
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Update motel (UC23)")
    public ResponseEntity<ApiResponse<MotelResult>> update(
            @PathVariable Long id, @RequestBody MotelPatchRequestBody body) {
        MotelResult result = motelService.update(id, toPatchCommand(body));
        return ResponseEntity.ok(ApiResponse.ok(result, "Motel updated"));
    }

    @PutMapping("/{id}/payment-config")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Save payment configuration (webhook secret and bank details)")
    public ResponseEntity<ApiResponse<Void>> savePaymentConfig(
            @PathVariable Long id,
            @Valid @RequestBody PaymentConfigRequestBody body) {
        motelService.savePaymentConfig(id, body.accountNumber(), body.bankName());
        return ResponseEntity.ok(ApiResponse.ok("Payment configuration saved"));
    }

    @GetMapping("/generate-secret")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Generate a secure random secret key for webhook integration")
    public ResponseEntity<ApiResponse<String>> generateSecret() {
        ApiResponse<String> response = ApiResponse.<String>builder()
                .success(true)
                .code("SUCCESS")
                .data(motelService.generateSecureRandomSecret())
                .build();
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    @Operation(summary = "Delete motel (UC25)")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        motelService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok("Motel deleted"));
    }

    private MotelUpsertCommand toCommand(MotelUpsertRequestBody body) {
        return new MotelUpsertCommand(
                body.name(),
                body.address(),
                body.totalFloors(),
                body.description(),
                body.billingCycleDay(),
                body.depositPercent(),
                body.bankConfig()
        );
    }

    private MotelUpsertCommand toPatchCommand(MotelPatchRequestBody body) {
        return new MotelUpsertCommand(
                body.name(),
                body.address(),
                body.totalFloors(),
                body.description(),
                body.billingCycleDay(),
                body.depositPercent(),
                body.bankConfig()
        );
    }
}

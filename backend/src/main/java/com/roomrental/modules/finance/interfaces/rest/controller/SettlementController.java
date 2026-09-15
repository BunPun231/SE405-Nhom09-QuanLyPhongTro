package com.roomrental.modules.finance.interfaces.rest.controller;

import com.roomrental.modules.finance.application.dto.*;
import com.roomrental.modules.finance.application.service.SettlementService;
import com.roomrental.modules.finance.interfaces.rest.dto.SettlementRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/settlements")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Finance - Settlements", description = "UC80")
public class SettlementController {

    private final SettlementService service;

    public SettlementController(SettlementService service) {
        this.service = service;
    }

    @PostMapping("/schedule-moveout")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Schedule move out date (UC81)")
    public ResponseEntity<Void> scheduleMoveOut(@RequestBody @Valid com.roomrental.modules.finance.interfaces.rest.dto.SettlementScheduleMoveOutRequest request) {
        SettlementScheduleMoveOutCommand cmd = new SettlementScheduleMoveOutCommand(
            request.contractId(), request.moveOutDate(), request.moveOutReason()
        );
        service.scheduleMoveOut(cmd);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/calculate")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Calculate settlement balance for a contract (UC80)")
    public ResponseEntity<SettlementResult> calculate(@RequestBody @Valid SettlementRequest request) {
        SettlementCommand cmd = new SettlementCommand(
            request.contractId(), request.moveOutDate(), request.finalElectricReading(), request.finalWaterReading(),
            request.damages()
        );
        return ResponseEntity.ok(service.calculate(cmd));
    }

    @PostMapping("/{contractId}/confirm")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Confirm settlement and liquidate contract (UC80)")
    public ResponseEntity<SettlementConfirmationResult> confirmSettlement(
            @PathVariable Long contractId,
            @RequestBody @Valid com.roomrental.modules.finance.interfaces.rest.dto.SettlementConfirmRequest request) {
        SettlementConfirmCommand cmd = new SettlementConfirmCommand(
            contractId, request.moveOutDate(), request.finalElectricReading(), request.finalWaterReading(), request.damages()
        );
        return ResponseEntity.ok(service.confirmSettlement(cmd));
    }
}

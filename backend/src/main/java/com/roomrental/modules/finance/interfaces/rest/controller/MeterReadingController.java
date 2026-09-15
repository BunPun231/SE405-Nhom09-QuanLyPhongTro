package com.roomrental.modules.finance.interfaces.rest.controller;

import com.roomrental.modules.finance.application.dto.*;
import com.roomrental.modules.finance.application.service.MeterReadingService;
import com.roomrental.modules.finance.interfaces.rest.dto.MeterReadingOcrRequest;
import com.roomrental.modules.finance.interfaces.rest.dto.MeterReadingRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Base64;
import java.util.List;
import com.roomrental.common.util.HashidsCodec;
import com.roomrental.common.exception.BaseException;

@RestController
@RequestMapping("/api/v1/meter-readings")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Finance - Meter Readings", description = "UC70, UC71, UC72")
public class MeterReadingController {

    private final MeterReadingService service;
    private final HashidsCodec hashidsCodec;

    public MeterReadingController(MeterReadingService service, HashidsCodec hashidsCodec) {
        this.service = service;
        this.hashidsCodec = hashidsCodec;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "List meter readings (UC72)")
    public ResponseEntity<org.springframework.data.domain.Page<MeterReadingResult>> list(
            @RequestParam(required = false) Long roomId,
            @RequestParam(required = false) String status,
            org.springframework.data.domain.Pageable pageable) {
        return ResponseEntity.ok(service.list(roomId, status, pageable));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Submit a meter reading manually (UC70)")
    public ResponseEntity<MeterReadingResult> submit(@RequestBody @Valid MeterReadingRequest request) {
        MeterReadingSubmitCommand cmd = new MeterReadingSubmitCommand(
            request.roomId(), request.serviceId(), request.billingMonth(),
            request.newReading(), request.readingImageUrl()
        );
        return ResponseEntity.ok(service.submit(cmd));
    }

    @PostMapping("/ocr")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Extract reading using OCR and return suggestion (UC71)")
    public ResponseEntity<MeterReadingResult> submitWithOcr(@RequestBody @Valid MeterReadingOcrRequest request) {
        byte[] imageBytes = Base64.getDecoder().decode(request.base64Image());
        MeterReadingOcrCommand cmd = new MeterReadingOcrCommand(
            request.roomId(), request.serviceId(), request.billingMonth(),
            imageBytes, request.mimeType()
        );
        return ResponseEntity.ok(service.submitWithOcr(cmd));
    }

    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Approve a reading (UC70)")
    public ResponseEntity<MeterReadingResult> approve(@PathVariable Long id) {
        return ResponseEntity.ok(service.approve(id));
    }

    @PostMapping("/bulk-approve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Bulk approve readings (UC70)")
    public ResponseEntity<List<MeterReadingResult>> bulkApprove(@RequestBody List<Long> ids) {
        return ResponseEntity.ok(service.bulkApprove(new MeterReadingBulkApproveCommand(ids)));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Reject a reading (UC70)")
    public ResponseEntity<MeterReadingResult> reject(@PathVariable Long id, @RequestParam String reason) {
        return ResponseEntity.ok(service.reject(id, reason));
    }

    @GetMapping("/rooms/{roomId}/history")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Get reading history for a room (UC72)")
    public ResponseEntity<List<MeterReadingResult>> getHistory(@PathVariable String roomId) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) {
            try {
                decoded = Long.parseLong(roomId);
            } catch (NumberFormatException e) {
                throw BaseException.badRequest("roomId: invalid");
            }
        }
        return ResponseEntity.ok(service.getHistory(decoded));
    }

    @GetMapping("/rooms/{roomId}/trend")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'RESIDENT')")
    @Operation(summary = "Get reading trend chart data (UC72)")
    public ResponseEntity<List<MeterReadingResult>> getConsumptionTrend(
            @PathVariable String roomId, 
            @RequestParam(defaultValue = "6") int months) {
        Long decoded = hashidsCodec.decode(roomId);
        if (decoded == null) {
            try {
                decoded = Long.parseLong(roomId);
            } catch (NumberFormatException e) {
                throw BaseException.badRequest("roomId: invalid");
            }
        }
        return ResponseEntity.ok(service.getConsumptionTrend(decoded, months));
    }

}

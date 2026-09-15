package com.roomrental.modules.contract.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.dto.PageResponse;
import com.roomrental.modules.contract.application.dto.ContractAdjustmentRequest;
import com.roomrental.modules.contract.application.dto.ContractAppendixResult;
import com.roomrental.modules.contract.application.dto.ContractCreateCommand;
import com.roomrental.modules.contract.application.dto.ContractDetailResult;
import com.roomrental.modules.contract.application.dto.ContractResult;
import com.roomrental.modules.contract.application.dto.ContractServiceItemCommand;
import com.roomrental.modules.contract.application.service.ContractService;
import com.roomrental.modules.contract.interfaces.rest.dto.ContractAdjustmentRequestBody;
import com.roomrental.modules.contract.interfaces.rest.dto.ContractCreateRequestBody;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller cho Contract Management.
 * Endpoints: POST, GET, PATCH, DELETE, Adjustments, Cancel, Deposit.
 */
@RestController
@RequestMapping("/api/contracts")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Contract Management", description = "Quản lý hợp đồng thuê phòng")
public class ContractController {
    private final ContractService contractService;

    public ContractController(ContractService contractService) {
        this.contractService = contractService;
    }

    /**
     * Tạo hợp đồng mới (DRAFT status).
     * POST /api/contracts
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<ContractResult>> create(@Valid @RequestBody ContractCreateRequestBody body) {
        ContractCreateCommand command = new ContractCreateCommand(
                body.roomId(),
                body.primaryResidentUserId(),
                body.primaryResidentPhone(),
                body.primaryResidentFullName(),
                body.primaryResidentEmail(),
                body.primaryResidentIdCardNumber(),
                body.primaryResidentIdCardFrontUrl(),
                body.primaryResidentIdCardBackUrl(),
            body.rentPrice(),
                body.startDate(),
                body.endDate(),
                body.depositAmount(),
                body.depositStatus(),
            body.billingDate(),
            body.billingCycleDay(),
            body.paymentCycleMonths(),
            body.residentUserIds(),
            body.serviceItems() != null
                ? body.serviceItems().stream()
                .map(item -> new ContractServiceItemCommand(item.serviceId(), item.quantity(), null))
                .toList()
                : List.of()
        );
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(contractService.create(command), "Contract created"));
    }

    /**
     * Lấy hợp đồng theo ID.
     * GET /api/contracts/{id}
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','RESIDENT')")
    public ResponseEntity<ApiResponse<ContractResult>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(contractService.getById(id)));
    }

    /**
     * Chi tiết hợp đồng.
     * GET /api/contracts/{id}/detail
     */
    @GetMapping("/{id}/detail")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','RESIDENT')")
    public ResponseEntity<ApiResponse<ContractDetailResult>> getDetail(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(contractService.getDetail(id)));
    }

    /**
     * Danh sách phụ lục hợp đồng (phân trang).
     * GET /api/contracts/{id}/appendices
     */
    @GetMapping("/{id}/appendices")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','RESIDENT')")
    public ResponseEntity<ApiResponse<PageResponse<ContractAppendixResult>>> getAppendices(
            @PathVariable Long id,
            @Parameter(description = "Page number (0-based), size, sort - e.g. sort=effectiveDate,desc")
            @PageableDefault(size = 20, sort = "effectiveDate", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.ok(
                PageResponse.from(contractService.getAppendicesByContract(id, pageable))
        ));
    }

    /**
     * Chi tiết phụ lục hợp đồng.
     * GET /api/contracts/appendices/{appendixId}
     */
    @GetMapping("/appendices/{appendixId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','RESIDENT')")
    public ResponseEntity<ApiResponse<ContractAppendixResult>> getAppendixDetail(
            @PathVariable Long appendixId) {
        return ResponseEntity.ok(ApiResponse.ok(contractService.getAppendixDetail(appendixId)));
    }

    /**
     * Lấy danh sách hợp đồng của tenant hiện tại.
     * GET /api/contracts
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<List<ContractResult>>> list() {
        return ResponseEntity.ok(ApiResponse.ok(contractService.listByTenant()));
    }

    /**
     * Lấy danh sách hợp đồng theo nhà trọ.
     * GET /api/contracts/motels/{motelId}
     */
    @GetMapping("/motels/{motelId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<PageResponse<ContractResult>>> listByMotel(
            @PathVariable Long motelId,
            @Parameter(description = "Filter by status (ACTIVE, DRAFT, CANCELED, LIQUIDATED, PENDING_LIQUIDATION)")
            @RequestParam(required = false) String status,
            @Parameter(description = "Filter expiring contracts within next 30 days")
            @RequestParam(required = false, defaultValue = "false") boolean expiring,
            @Parameter(description = "From date (yyyy-MM-dd)")
            @RequestParam(required = false) LocalDate fromDate,
            @Parameter(description = "To date (yyyy-MM-dd)")
            @RequestParam(required = false) LocalDate toDate,
            @Parameter(description = "Page number (0-based), size, sort - e.g. sort=createdAt,desc")
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        if (expiring) {
            LocalDate from = fromDate != null ? fromDate : LocalDate.now();
            LocalDate to = toDate != null ? toDate : LocalDate.now().plusDays(30);
            return ResponseEntity.ok(ApiResponse.ok(
                    PageResponse.from(contractService.listExpiringByMotel(motelId, from, to, pageable))
            ));
        }

        if (status != null && !status.isBlank()) {
            return ResponseEntity.ok(ApiResponse.ok(
                    PageResponse.from(contractService.listByMotelAndStatus(motelId, status, pageable))
            ));
        }

        return ResponseEntity.ok(ApiResponse.ok(
                PageResponse.from(contractService.listByMotel(motelId, pageable))
        ));
    }

    /**
     * Lấy danh sách hợp đồng đang hiệu lực (ACTIVE).
     * GET /api/contracts/active
     */
    @GetMapping("/active")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<List<ContractResult>>> listActive() {
        return ResponseEntity.ok(ApiResponse.ok(contractService.listActiveByTenant()));
    }

    /**
     * Lấy danh sách hợp đồng của một cư dân.
     * GET /api/contracts/resident/{residentUserId}
     */
    @GetMapping("/resident/{residentUserId}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','RESIDENT')")
    public ResponseEntity<ApiResponse<List<ContractResult>>> listByResident(@PathVariable String residentUserId) {
        return ResponseEntity.ok(ApiResponse.ok(contractService.listByResident(residentUserId)));
    }


    /**
     * Kích hoạt hợp đồng (chuyển từ DRAFT → ACTIVE).
     * POST /api/contracts/{id}/activate
     */
    // @PostMapping("/{id}/activate")
    // @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    // public ResponseEntity<ApiResponse<ContractResult>> activate(@PathVariable Long id) {
    //     return ResponseEntity.ok(ApiResponse.ok(contractService.activate(id)));
    // }


    /**
     * Xuat PDF hop dong.
     * GET /api/contracts/{id}/pdf
     */
    @GetMapping("/{id}/pdf")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<byte[]> exportPdf(@PathVariable Long id) {
        byte[] pdf = contractService.exportPdf(id);
        String filename = "contract_" + id + "_" + LocalDate.now() + ".pdf";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    // ========================
    // UC66: Contract Adjustments
    // ========================

    /**
     * Điều chỉnh hợp đồng (UC66).
     * POST /api/contracts/{contractId}/adjustments
     */
    @Operation(summary = "Adjust contract", description = "Price change, renew, move-out notice, or manual clause")
    @PostMapping("/{contractId}/adjustments")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<ContractAppendixResult>> adjust(
            @PathVariable Long contractId,
            @Valid @RequestBody ContractAdjustmentRequestBody body
    ) {
        ContractAdjustmentRequest request = new ContractAdjustmentRequest(
                body.type(),
                body.effectiveDate(),
                body.newRentPrice(),
                body.newEndDate(),
            body.intendedMoveOutDate(),
            body.metadata(),
            body.applyToCurrentContracts(),
            body.newServicePrices()
        );
        ContractAppendixResult result = contractService.adjust(contractId, request);
        return ResponseEntity.ok(ApiResponse.ok(result, "Contract adjusted"));
    }

    // ========================
    // UC67: Cancel Contract (soft delete)
    // ========================

    /**
     * Hủy hợp đồng (UC67) - chuyển sang CANCELED.
     * POST /api/contracts/{id}/cancel
     */
    @Operation(summary = "Cancel contract", description = "Soft-delete: set status to CANCELED and release room")
    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<ContractResult>> cancel(
            @PathVariable Long id,
            @RequestParam(required = false) String reason) {
        return ResponseEntity.ok(ApiResponse.ok(contractService.cancel(id, reason), "Contract canceled"));
    }

    // ========================
    // UC69: Deposit Management
    // ========================

    /**
     * Thu tiền cọc (UNPAID → PAID).
     * POST /api/contracts/{id}/deposit/collect
     */
    @Operation(summary = "Collect deposit", description = "Mark deposit as PAID")
    @PostMapping("/{id}/deposit/collect")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN')")
    public ResponseEntity<ApiResponse<ContractResult>> collectDeposit(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(contractService.collectDeposit(id), "Deposit collected"));
    }
}
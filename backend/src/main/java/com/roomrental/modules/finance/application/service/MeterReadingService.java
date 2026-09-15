package com.roomrental.modules.finance.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.finance.application.dto.*;
import com.roomrental.modules.finance.application.event.*;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.model.MeterReading.MeterReadingStatus;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.port.OcrPort;
import com.roomrental.modules.finance.domain.port.OcrResult;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class MeterReadingService {
    
    private final MeterReadingRepository meterReadingRepository;
    private final ServiceUsageRepository serviceUsageRepository;
    private final OcrPort ocrPort;
    private final ApplicationEventPublisher eventPublisher;
    private final CloudinaryService cloudinaryService;
    private final RoomRepository roomRepository;
    private final RentalServiceRepository rentalServiceRepository;

    public MeterReadingService(
            MeterReadingRepository meterReadingRepository,
            ServiceUsageRepository serviceUsageRepository,
            OcrPort ocrPort,
            ApplicationEventPublisher eventPublisher,
            CloudinaryService cloudinaryService,
            RoomRepository roomRepository,
            RentalServiceRepository rentalServiceRepository) {
        this.meterReadingRepository = meterReadingRepository;
        this.serviceUsageRepository = serviceUsageRepository;
        this.ocrPort = ocrPort;
        this.eventPublisher = eventPublisher;
        this.cloudinaryService = cloudinaryService;
        this.roomRepository = roomRepository;
        this.rentalServiceRepository = rentalServiceRepository;
    }

    @Transactional
    public MeterReadingResult submit(MeterReadingSubmitCommand command) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UUID actorId = SecurityUtils.getCurrentUserId();
        LocalDate billingMonth = normalizeBillingMonth(command.billingMonth());

        Room room = roomRepository.findById(command.roomId())
                .orElseThrow(() -> BaseException.notFound("Room", command.roomId()));
        if (room.getStatus() == RoomStatus.EMPTY || room.getStatus() == RoomStatus.OUT_OF_BUSINESS) {
            throw BaseException.badRequest("Cannot submit reading for EMPTY or OUT_OF_BUSINESS room");
        }

        // 1. Validate only 1 APPROVED per billingMonth per service
        Long serviceUsageId = resolveActiveServiceUsageId(command.roomId(), command.serviceId());

        boolean hasApproved = meterReadingRepository.existsByServiceUsageIdAndBillingMonthAndStatus(
            serviceUsageId, billingMonth, MeterReadingStatus.APPROVED.name()
        );
        if (hasApproved) {
            throw BaseException.badRequest("Already has approved reading for this month");
        }

        BigDecimal oldReading = resolveOldReading(serviceUsageId);

        if (command.newReading().compareTo(oldReading) < 0) {
            throw BaseException.badRequest("New reading cannot be less than old reading");
        }

        MeterReading reading = new MeterReading();
        reading.setTenantId(tenantId);
        reading.setRoomId(command.roomId());
        reading.setServiceUsageId(serviceUsageId);
        reading.setBillingMonth(billingMonth);
        reading.setOldReading(oldReading);
        reading.setNewReading(command.newReading());
        reading.calculateConsumption();
        reading.setReadingImageUrl(command.readingImageUrl());
        
        String role = SecurityUtils.getCurrentRole();
        if ("MANAGER".equals(role) || "ADMIN".equals(role)) {
            reading.setStatus(MeterReadingStatus.APPROVED);
            reading.setApprovedBy(actorId);
        } else {
            reading.setStatus(MeterReadingStatus.PENDING);
        }
        
        reading.setSubmittedBy(actorId);
        reading.setCreatedAt(OffsetDateTime.now());
        reading.setUpdatedAt(OffsetDateTime.now());

        MeterReading saved = meterReadingRepository.save(reading);

        eventPublisher.publishEvent(new MeterReadingSubmittedEvent(
            tenantId, actorId, SecurityUtils.getCurrentRole(),
            saved.getId(), saved.getRoomId(), saved.getNewReading().toPlainString()
        ));

        return toResult(saved, null);
    }

    @Transactional(readOnly = true)
    public MeterReadingResult submitWithOcr(MeterReadingOcrCommand command) {
        Room room = roomRepository.findById(command.roomId())
                .orElseThrow(() -> BaseException.notFound("Room", command.roomId()));
        if (room.getStatus() == RoomStatus.EMPTY || room.getStatus() == RoomStatus.OUT_OF_BUSINESS) {
            throw BaseException.badRequest("Cannot submit reading for EMPTY or OUT_OF_BUSINESS room");
        }

        Long serviceUsageId = resolveActiveServiceUsageId(command.roomId(), command.serviceId());
        LocalDate billingMonth = normalizeBillingMonth(command.billingMonth());

        // UC71 - Just return suggested result, do not save and do not upload to Cloudinary at this step
        OcrResult ocrResult = ocrPort.extractReading(command.imageBytes(), command.mimeType());
        
        if (ocrResult == null || ocrResult.extractedValue() == null) {
            throw BaseException.badRequest("Failed to extract reading from image");
        }

        String imageUrl = null;

        BigDecimal oldReading = resolveOldReading(serviceUsageId);
        BigDecimal consumption = ocrResult.extractedValue().subtract(oldReading).max(BigDecimal.ZERO);

        RentalService svc = rentalServiceRepository.findById(command.serviceId()).orElse(null);
        String serviceName = svc != null ? svc.getName() : null;

        return new MeterReadingResult(
            null,
            command.roomId(),
            command.serviceId(),
            serviceName,
            billingMonth,
            oldReading,
            ocrResult.extractedValue(),
            consumption,
            MeterReadingStatus.PENDING.name(),
            imageUrl,
            ocrResult.confidence(),
            null,
            null
        );
    }

    @Transactional
    public MeterReadingResult approve(Long id) {
        UUID tenantId = SecurityUtils.requireTenantId();
        MeterReading reading = meterReadingRepository.findByIdAndTenantId(id, tenantId)
            .orElseThrow(() -> BaseException.notFound("MeterReading", id));

        if (!reading.canBeApproved()) {
            throw BaseException.badRequest("Reading is not PENDING");
        }

        // Anomaly logic (BR70.7) - > 130% avg. Skipped for brevity, can add later.

        reading.setStatus(MeterReadingStatus.APPROVED);
        reading.setApprovedBy(SecurityUtils.getCurrentUserId());
        reading.setUpdatedAt(OffsetDateTime.now());
        
        MeterReading saved = meterReadingRepository.save(reading);

        eventPublisher.publishEvent(new MeterReadingApprovedEvent(
            tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
            saved.getId(), saved.getStatus().name()
        ));

        return toResult(saved, null);
    }

    @Transactional
    public List<MeterReadingResult> bulkApprove(MeterReadingBulkApproveCommand command) {
        return command.ids().stream().map(this::approve).collect(Collectors.toList());
    }

    @Transactional
    public MeterReadingResult reject(Long id, String reason) {
        UUID tenantId = SecurityUtils.requireTenantId();
        MeterReading reading = meterReadingRepository.findByIdAndTenantId(id, tenantId)
            .orElseThrow(() -> BaseException.notFound("MeterReading", id));

        if (!reading.canBeApproved()) {
            throw BaseException.badRequest("Reading is not PENDING");
        }

        reading.setStatus(MeterReadingStatus.REJECTED);
        reading.setUpdatedAt(OffsetDateTime.now());
        
        MeterReading saved = meterReadingRepository.save(reading);
        return toResult(saved, null);
    }

    @Transactional(readOnly = true)
    public Page<MeterReadingResult> list(Long roomId, String status, Pageable pageable) {
        UUID tenantId = SecurityUtils.requireTenantId();
        Page<MeterReading> page;
        
        if (roomId != null && status != null && !status.isEmpty()) {
            page = meterReadingRepository.findByTenantIdAndRoomIdAndStatus(tenantId, roomId, status, pageable);
        } else if (roomId != null) {
            page = meterReadingRepository.findByTenantIdAndRoomId(tenantId, roomId, pageable);
        } else if (status != null && !status.isEmpty()) {
            page = meterReadingRepository.findByTenantIdAndStatus(tenantId, status, pageable);
        } else {
            page = meterReadingRepository.findByTenantId(tenantId, pageable);
        }
        
        return page.map(r -> toResult(r, null));
    }

    @Transactional(readOnly = true)
    public List<MeterReadingResult> getHistory(Long roomId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return meterReadingRepository.findByRoomIdAndTenantId(roomId, tenantId).stream()
            .filter(r -> r.getStatus() == MeterReadingStatus.APPROVED)
            // Should be sorted by DB, but here's fallback sort
            .sorted((a,b) -> b.getBillingMonth().compareTo(a.getBillingMonth()))
            .map(r -> toResult(r, null))
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MeterReadingResult> getConsumptionTrend(Long roomId, int months) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return getHistory(roomId).stream()
            .limit(months)
            .collect(Collectors.toList());
    }

    private MeterReadingResult toResult(MeterReading reading, Double confidence) {
        Long serviceId = null;
        String serviceName = null;
        if (reading.getServiceUsageId() != null) {
            ServiceUsage usage = serviceUsageRepository.findById(reading.getServiceUsageId()).orElse(null);
            if (usage != null) {
                serviceId = usage.getServiceId();
                if (serviceId != null) {
                    RentalService svc = rentalServiceRepository.findById(serviceId).orElse(null);
                    serviceName = svc != null ? svc.getName() : null;
                }
            }
        }

        return new MeterReadingResult(
            reading.getId(),
            reading.getRoomId(),
            serviceId,
            serviceName,
            reading.getBillingMonth(),
            reading.getOldReading(),
            reading.getNewReading(),
            reading.getConsumption(),
            reading.getStatus() != null ? reading.getStatus().name() : null,
            reading.getReadingImageUrl(),
            confidence,
            reading.getCreatedAt(),
            reading.getUpdatedAt()
        );
    }

    private LocalDate normalizeBillingMonth(LocalDate billingMonth) {
        if (billingMonth == null) {
            throw BaseException.badRequest("billingMonth: required");
        }
        return billingMonth.withDayOfMonth(1);
    }

    private Long resolveActiveServiceUsageId(Long roomId, Long serviceId) {
        return serviceUsageRepository.findActiveByRoomIdAndServiceId(roomId, serviceId)
                .orElseThrow(() -> BaseException.badRequest("Phòng chưa đăng ký sử dụng dịch vụ này"))
                .getId();
    }

    private BigDecimal resolveOldReading(Long serviceUsageId) {
        return meterReadingRepository.findLatestApprovedByServiceUsageId(serviceUsageId)
                .map(MeterReading::getNewReading)
                .or(() -> serviceUsageRepository.findById(serviceUsageId).map(ServiceUsage::getStartIndex))
                .orElse(BigDecimal.ZERO);
    }
}


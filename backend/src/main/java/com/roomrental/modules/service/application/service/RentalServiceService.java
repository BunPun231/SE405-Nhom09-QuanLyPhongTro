package com.roomrental.modules.service.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.motel.domain.model.Motel;
import com.roomrental.modules.motel.domain.repository.MotelRepository;
import com.roomrental.modules.finance.domain.model.ServiceUsage;
import com.roomrental.modules.finance.domain.repository.ServiceUsageRepository;
import com.roomrental.modules.finance.domain.model.MeterReading;
import com.roomrental.modules.finance.domain.repository.MeterReadingRepository;
import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.model.RoomStatus;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.service.application.dto.*;
import com.roomrental.modules.service.application.event.ServiceCreatedEvent;
import com.roomrental.modules.service.application.event.ServiceDeletedEvent;
import com.roomrental.modules.service.application.event.ServiceUpdatedEvent;
import com.roomrental.modules.service.domain.model.ChargeType;
import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.model.ServicePricing;
import com.roomrental.modules.service.domain.model.ServiceTierPricing;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.domain.repository.ServicePricingRepository;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Application service for Service management (UC32-UC36).
 */
@Service
public class RentalServiceService {

    private final RentalServiceRepository serviceRepository;
    private final ServicePricingRepository servicePricingRepository;
    private final MotelRepository motelRepository;
    private final RoomRepository roomRepository;
    private final ServiceUsageRepository serviceUsageRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final ApplicationEventPublisher eventPublisher;

    public RentalServiceService(
            RentalServiceRepository serviceRepository,
            ServicePricingRepository servicePricingRepository,
            MotelRepository motelRepository,
            RoomRepository roomRepository,
            ServiceUsageRepository serviceUsageRepository,
            MeterReadingRepository meterReadingRepository,
            ApplicationEventPublisher eventPublisher) {
        this.serviceRepository = serviceRepository;
        this.servicePricingRepository = servicePricingRepository;
        this.motelRepository = motelRepository;
        this.roomRepository = roomRepository;
        this.serviceUsageRepository = serviceUsageRepository;
        this.meterReadingRepository = meterReadingRepository;
        this.eventPublisher = eventPublisher;
    }

    @Transactional
    public ServiceResult create(Long motelId, ServiceCreateCommand command) {
        requireMotel(motelId);

        if (serviceRepository.existsByMotelIdAndName(motelId, command.name())) {
            throw BaseException.conflict("Service '" + command.name() + "' already exists in this motel");
        }

        RentalService svc = new RentalService();
        svc.setMotelId(motelId);
        svc.setName(command.name());
        svc.setChargeType(parseChargeType(command.chargeType()));
        svc.setUnit(command.unit());
        svc.setMandatory(command.mandatory() != null && command.mandatory());

        RentalService savedService = serviceRepository.save(svc);
        upsertPricing(savedService.getId(), command.basePrice(), command.pricingTiers());
        ServiceResult result = toResult(savedService);
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new ServiceCreatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), result.name()));
        return result;
    }

    @Transactional(readOnly = true)
    public PageResponse<ServiceResult> list(Long motelId, Pageable pageable) {
        requireMotel(motelId);
        return PageResponse.from(serviceRepository.findByMotelId(motelId, pageable), this::toResult);
    }

    /**
     * UC37+: List services assigned to a specific room.
     */
    @Transactional(readOnly = true)
    public List<ServiceResult> listByRoom(Long motelId, Long roomId) {
        requireMotel(motelId);
        List<ServiceUsage> usages = serviceUsageRepository.findActiveByRoomId(roomId);
        return usages.stream()
                .map(usage -> serviceRepository.findByIdAndMotelId(usage.getServiceId(), motelId))
                .filter(java.util.Optional::isPresent)
                .map(opt -> toResult(opt.get()))
                .toList();
    }

    @Transactional(readOnly = true)
    public ServiceResult get(Long motelId, Long serviceId) {
        return toResult(findService(motelId, serviceId));
    }

    @Transactional
    public ServiceResult update(Long motelId, Long serviceId, ServiceUpdateCommand command) {
        RentalService svc = findService(motelId, serviceId);
        String oldName = svc.getName();

        if (command.name() != null && !command.name().isBlank()) {
            if (!command.name().equals(svc.getName()) && serviceRepository.existsByMotelIdAndName(motelId, command.name())) {
                throw BaseException.conflict("Service '" + command.name() + "' already exists");
            }
            svc.setName(command.name());
        }
        if (command.chargeType() != null) {
            svc.setChargeType(parseChargeType(command.chargeType()));
        }
        if (command.unit() != null) {
            svc.setUnit(command.unit());
        }
        if (command.mandatory() != null) {
            svc.setMandatory(command.mandatory());
        }

        RentalService savedService = serviceRepository.save(svc);
        upsertPricing(savedService.getId(), command.basePrice(), command.pricingTiers());
        ServiceResult result = toResult(savedService);
        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new ServiceUpdatedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                result.id(), oldName, result.name()));
        return result;
    }

    @Transactional
    public void delete(Long motelId, Long serviceId) {
        RentalService svc = findService(motelId, serviceId);
        svc.setDeleted(true);
        serviceRepository.save(svc);

        UUID tenantId = SecurityUtils.requireTenantId();
        eventPublisher.publishEvent(new ServiceDeletedEvent(
                tenantId, SecurityUtils.getCurrentUserId(), SecurityUtils.getCurrentRole(),
                serviceId, svc.getName()));
    }

    @Transactional
    public void assignToRooms(Long motelId, Long serviceId, ServiceAssignCommand command) {
        requireMotel(motelId); // Validates tenantId owns motelId
        RentalService svc = findService(motelId, serviceId);

        for (ServiceAssignCommand.RoomAssignInput roomInput : command.rooms()) {
            Long roomId = roomInput.roomId();
            Room room = roomRepository.findById(roomId)
                    .orElseThrow(() -> BaseException.notFound("Room", roomId));
            
            if (!room.getMotelId().equals(motelId)) {
                throw BaseException.badRequest("Room " + roomId + " does not belong to the specified motel");
            }
            
            if (room.getStatus() == RoomStatus.OUT_OF_BUSINESS) {
                continue;
            }

            boolean alreadyAssigned = serviceUsageRepository.findBillableByRoomId(roomId)
                    .stream()
                    .anyMatch(u -> u.getServiceId().equals(serviceId));

            if (!alreadyAssigned) {
                ServiceUsage usage = new ServiceUsage();
                usage.setRoomId(roomId);
                usage.setServiceId(serviceId);
                usage.setRegisteredQuantity(roomInput.quantity() != null ? roomInput.quantity() : 1);
                usage.setStatus(ServiceUsage.ServiceUsageStatus.ACTIVE);
                usage.setRegisteredAt(OffsetDateTime.now());
                usage.setUpdatedAt(OffsetDateTime.now());
                ServiceUsage savedUsage = serviceUsageRepository.save(usage);
                
                if (roomInput.startIndex() != null) {
                    MeterReading reading = new MeterReading();
                    reading.setTenantId(SecurityUtils.requireTenantId());
                    reading.setRoomId(roomId);
                    reading.setServiceUsageId(savedUsage.getId());
                    reading.setBillingMonth(LocalDate.now().withDayOfMonth(1));
                    reading.setOldReading(roomInput.startIndex());
                    reading.setNewReading(roomInput.startIndex());
                    reading.setConsumption(BigDecimal.ZERO);
                    reading.setStatus(MeterReading.MeterReadingStatus.APPROVED);
                    reading.setApprovedBy(SecurityUtils.getCurrentUserId());
                    reading.setCreatedAt(OffsetDateTime.now());
                    reading.setUpdatedAt(OffsetDateTime.now());
                    meterReadingRepository.save(reading);
                }
            }
        }
    }

    private Motel requireMotel(Long motelId) {
        UUID tenantId = SecurityUtils.requireTenantId();
        return motelRepository.findByIdAndTenantId(motelId, tenantId)
                .orElseThrow(() -> BaseException.notFound("Motel", motelId));
    }

    private RentalService findService(Long motelId, Long serviceId) {
        requireMotel(motelId);
        return serviceRepository.findByIdAndMotelId(serviceId, motelId)
                .orElseThrow(() -> BaseException.notFound("Service", serviceId));
    }

    private ChargeType parseChargeType(String type) {
        try { return ChargeType.valueOf(type); }
        catch (IllegalArgumentException e) { throw BaseException.badRequest("Invalid charge type: " + type); }
    }

    private ServiceResult toResult(RentalService svc) {
        ServicePricing pricing = servicePricingRepository.findCurrentByServiceId(svc.getId(), LocalDate.now())
                .orElse(null);
        return new ServiceResult(svc.getId(), svc.getMotelId(), svc.getName(),
                svc.getChargeType().name(), svc.getUnit(), svc.isMandatory(),
                pricing != null ? pricing.getBasePrice() : null,
                pricing != null
                        ? pricing.getTierPrices().stream().map(this::toTierResult).toList()
                        : List.of());
    }

    private void upsertPricing(Long serviceId, BigDecimal basePrice, List<ServiceTierPricingCommand> tierCommands) {
        servicePricingRepository.closeCurrentPricing(serviceId, LocalDate.now().minusDays(1));

        ServicePricing pricing = new ServicePricing();
        pricing.setServiceId(serviceId);
        pricing.setEffectiveFrom(LocalDate.now());
        pricing.setBasePrice(basePrice);

        List<ServiceTierPricing> tiers = new ArrayList<>();
        if (tierCommands != null) {
            for (ServiceTierPricingCommand command : tierCommands) {
                ServiceTierPricing tier = new ServiceTierPricing();
                tier.setTierStart(command.tierStart());
                tier.setTierEnd(command.tierEnd());
                tier.setPricePerUnit(command.pricePerUnit());
                tiers.add(tier);
            }
        }
        pricing.setTierPrices(tiers);
        servicePricingRepository.save(pricing);
    }

    private ServiceTierPricingResult toTierResult(ServiceTierPricing tier) {
        return new ServiceTierPricingResult(tier.getTierStart(), tier.getTierEnd(), tier.getPricePerUnit());
    }
}

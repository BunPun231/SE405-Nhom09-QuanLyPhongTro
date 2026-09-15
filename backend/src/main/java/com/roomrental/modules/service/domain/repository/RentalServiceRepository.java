package com.roomrental.modules.service.domain.repository;

import com.roomrental.modules.service.domain.model.RentalService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;

public interface RentalServiceRepository {

    RentalService save(RentalService service);

    Optional<RentalService> findByIdAndMotelId(Long id, Long motelId);
    
    Optional<RentalService> findById(Long id);

    Page<RentalService> findByMotelId(Long motelId, Pageable pageable);

    List<RentalService> findByMotelIdAndMandatory(Long motelId, boolean mandatory);

    boolean existsByMotelIdAndName(Long motelId, String name);
}

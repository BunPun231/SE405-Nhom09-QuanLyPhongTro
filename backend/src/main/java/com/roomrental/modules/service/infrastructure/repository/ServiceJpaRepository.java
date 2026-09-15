package com.roomrental.modules.service.infrastructure.repository;

import com.roomrental.modules.service.infrastructure.entity.ServiceEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ServiceJpaRepository extends JpaRepository<ServiceEntity, Long> {
    Optional<ServiceEntity> findByIdAndMotelId(Long id, Long motelId);
    Page<ServiceEntity> findByMotelId(Long motelId, Pageable pageable);
    List<ServiceEntity> findByMotelIdAndMandatory(Long motelId, boolean mandatory);
    boolean existsByMotelIdAndName(Long motelId, String name);
    long countByMotelId(Long motelId);
}

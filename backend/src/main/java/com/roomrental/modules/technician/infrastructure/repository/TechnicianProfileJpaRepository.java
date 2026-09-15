package com.roomrental.modules.technician.infrastructure.repository;

import com.roomrental.modules.technician.infrastructure.entity.TechnicianProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TechnicianProfileJpaRepository extends JpaRepository<TechnicianProfileEntity, UUID> {
}

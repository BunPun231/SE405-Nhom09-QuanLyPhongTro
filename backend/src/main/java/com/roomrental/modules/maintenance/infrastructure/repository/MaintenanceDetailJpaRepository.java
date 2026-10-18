package com.roomrental.modules.maintenance.infrastructure.repository;

import com.roomrental.modules.maintenance.infrastructure.entity.MaintenanceDetailEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MaintenanceDetailJpaRepository extends JpaRepository<MaintenanceDetailEntity, Long> {
    List<MaintenanceDetailEntity> findByTicketId(Long ticketId);
}

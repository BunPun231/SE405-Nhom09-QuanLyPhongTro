package com.roomrental.modules.maintenance.infrastructure.repository;

import com.roomrental.modules.maintenance.infrastructure.entity.MaintenanceTicketEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MaintenanceTicketJpaRepository extends JpaRepository<MaintenanceTicketEntity, Long> {
    Page<MaintenanceTicketEntity> findByRoomIdIn(List<Long> roomIds, Pageable pageable);
    Page<MaintenanceTicketEntity> findByAssignedTo(UUID assignedTo, Pageable pageable);
    Page<MaintenanceTicketEntity> findByReportedBy(UUID reportedBy, Pageable pageable);
    List<MaintenanceTicketEntity> findByRoomId(Long roomId);
}

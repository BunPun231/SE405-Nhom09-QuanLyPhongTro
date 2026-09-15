package com.roomrental.modules.room.infrastructure.repository;

import com.roomrental.modules.room.infrastructure.entity.RoomEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface RoomJpaRepository extends JpaRepository<RoomEntity, Long> {

    Optional<RoomEntity> findByIdAndMotelId(Long id, Long motelId);

    Page<RoomEntity> findByMotelId(Long motelId, Pageable pageable);

    boolean existsByMotelIdAndRoomNumber(Long motelId, String roomNumber);

    @Query("SELECT COUNT(r) FROM RoomEntity r WHERE r.motelId IN (SELECT m.id FROM MotelEntity m WHERE m.tenantId = :tenantId AND m.deleted = false)")
    long countByTenantId(@Param("tenantId") java.util.UUID tenantId);
}

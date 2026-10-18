package com.roomrental.modules.device.infrastructure.repository;

import com.roomrental.modules.device.infrastructure.entity.DeviceEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface DeviceJpaRepository extends JpaRepository<DeviceEntity, Long> {
    Optional<DeviceEntity> findByIdAndMotelId(Long id, Long motelId);
    Page<DeviceEntity> findByMotelId(Long motelId, Pageable pageable);

    @Query(value = "SELECT * FROM devices WHERE motel_id = :motelId",
           countQuery = "SELECT count(*) FROM devices WHERE motel_id = :motelId",
           nativeQuery = true)
    Page<DeviceEntity> findByMotelIdIncludingDeleted(@Param("motelId") Long motelId, Pageable pageable);

    @Query(value = "SELECT * FROM devices WHERE id = :id AND motel_id = :motelId", nativeQuery = true)
    Optional<DeviceEntity> findByIdAndMotelIdIncludingDeleted(@Param("id") Long id, @Param("motelId") Long motelId);
}

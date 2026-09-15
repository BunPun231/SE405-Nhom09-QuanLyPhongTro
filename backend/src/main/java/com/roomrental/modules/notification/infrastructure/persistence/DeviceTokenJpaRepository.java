package com.roomrental.modules.notification.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceTokenJpaRepository extends JpaRepository<DeviceTokenEntity, Long> {
    List<DeviceTokenEntity> findByUserId(UUID userId);
    Optional<DeviceTokenEntity> findByToken(String token);
    void deleteByToken(String token);
}

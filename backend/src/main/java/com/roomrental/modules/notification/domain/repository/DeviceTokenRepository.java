package com.roomrental.modules.notification.domain.repository;

import com.roomrental.modules.notification.domain.model.DeviceToken;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeviceTokenRepository {
    DeviceToken save(DeviceToken deviceToken);
    List<DeviceToken> findByUserId(UUID userId);
    Optional<DeviceToken> findByToken(String token);
    void deleteByToken(String token);
}

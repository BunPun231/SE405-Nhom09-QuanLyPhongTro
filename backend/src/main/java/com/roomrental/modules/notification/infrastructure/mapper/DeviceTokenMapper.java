package com.roomrental.modules.notification.infrastructure.mapper;

import com.roomrental.modules.notification.domain.model.DeviceToken;
import com.roomrental.modules.notification.infrastructure.persistence.DeviceTokenEntity;
import org.springframework.stereotype.Component;

@Component
public class DeviceTokenMapper {

    public DeviceToken toDomain(DeviceTokenEntity entity) {
        if (entity == null) return null;
        DeviceToken domain = new DeviceToken();
        domain.setId(entity.getId());
        domain.setUserId(entity.getUserId());
        domain.setToken(entity.getToken());
        domain.setCreatedAt(entity.getCreatedAt());
        domain.setUpdatedAt(entity.getUpdatedAt());
        return domain;
    }

    public DeviceTokenEntity toEntity(DeviceToken domain) {
        if (domain == null) return null;
        DeviceTokenEntity entity = new DeviceTokenEntity();
        entity.setId(domain.getId());
        entity.setUserId(domain.getUserId());
        entity.setToken(domain.getToken());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setUpdatedAt(domain.getUpdatedAt());
        return entity;
    }
}

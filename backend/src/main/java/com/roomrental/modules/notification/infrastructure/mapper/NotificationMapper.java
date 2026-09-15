package com.roomrental.modules.notification.infrastructure.mapper;

import com.roomrental.modules.notification.domain.model.Notification;
import com.roomrental.modules.notification.infrastructure.persistence.NotificationEntity;
import org.springframework.stereotype.Component;

@Component
public class NotificationMapper {
    
    public Notification toDomain(NotificationEntity entity) {
        if (entity == null) return null;
        Notification domain = new Notification();
        domain.setId(entity.getId());
        domain.setTenantId(entity.getTenantId());
        domain.setRecipientUserId(entity.getRecipientUserId());
        domain.setTitle(entity.getTitle());
        domain.setContent(entity.getContent());
        domain.setType(entity.getType());
        domain.setRead(entity.isRead());
        domain.setActionUrl(entity.getActionUrl());
        domain.setCreatedAt(entity.getCreatedAt());
        domain.setReadAt(entity.getReadAt());
        return domain;
    }

    public NotificationEntity toEntity(Notification domain) {
        if (domain == null) return null;
        NotificationEntity entity = new NotificationEntity();
        entity.setId(domain.getId());
        entity.setTenantId(domain.getTenantId());
        entity.setRecipientUserId(domain.getRecipientUserId());
        entity.setTitle(domain.getTitle());
        entity.setContent(domain.getContent());
        entity.setType(domain.getType());
        entity.setRead(domain.isRead());
        entity.setActionUrl(domain.getActionUrl());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setReadAt(domain.getReadAt());
        return entity;
    }
}

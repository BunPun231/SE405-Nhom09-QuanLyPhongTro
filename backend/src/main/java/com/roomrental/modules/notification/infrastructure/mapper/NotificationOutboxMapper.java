package com.roomrental.modules.notification.infrastructure.mapper;

import com.roomrental.modules.notification.domain.model.NotificationOutbox;
import com.roomrental.modules.notification.infrastructure.persistence.NotificationOutboxEntity;
import org.springframework.stereotype.Component;

@Component
public class NotificationOutboxMapper {

    public NotificationOutbox toDomain(NotificationOutboxEntity entity) {
        if (entity == null) return null;
        NotificationOutbox domain = new NotificationOutbox();
        domain.setId(entity.getId());
        domain.setTenantId(entity.getTenantId());
        domain.setRecipientUserId(entity.getRecipientUserId());
        domain.setTitle(entity.getTitle());
        domain.setContent(entity.getContent());
        domain.setType(entity.getType());
        domain.setActionUrl(entity.getActionUrl());
        domain.setStatus(entity.getStatus());
        domain.setRetryCount(entity.getRetryCount());
        domain.setErrorMessage(entity.getErrorMessage());
        domain.setCreatedAt(entity.getCreatedAt());
        domain.setUpdatedAt(entity.getUpdatedAt());
        return domain;
    }

    public NotificationOutboxEntity toEntity(NotificationOutbox domain) {
        if (domain == null) return null;
        NotificationOutboxEntity entity = new NotificationOutboxEntity();
        entity.setId(domain.getId());
        entity.setTenantId(domain.getTenantId());
        entity.setRecipientUserId(domain.getRecipientUserId());
        entity.setTitle(domain.getTitle());
        entity.setContent(domain.getContent());
        entity.setType(domain.getType());
        entity.setActionUrl(domain.getActionUrl());
        entity.setStatus(domain.getStatus());
        entity.setRetryCount(domain.getRetryCount());
        entity.setErrorMessage(domain.getErrorMessage());
        entity.setCreatedAt(domain.getCreatedAt());
        entity.setUpdatedAt(domain.getUpdatedAt());
        return entity;
    }
}

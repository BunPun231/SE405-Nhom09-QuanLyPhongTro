package com.roomrental.modules.notification.infrastructure.adapter;

import com.roomrental.modules.notification.domain.model.Notification;
import com.roomrental.modules.notification.domain.repository.NotificationRepository;
import com.roomrental.modules.notification.infrastructure.mapper.NotificationMapper;
import com.roomrental.modules.notification.infrastructure.persistence.NotificationEntity;
import com.roomrental.modules.notification.infrastructure.persistence.NotificationJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
public class NotificationRepositoryAdapter implements NotificationRepository {

    private final NotificationJpaRepository jpaRepository;
    private final NotificationMapper mapper;

    public NotificationRepositoryAdapter(NotificationJpaRepository jpaRepository, NotificationMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    @Transactional
    public Notification save(Notification notification) {
        NotificationEntity entity = mapper.toEntity(notification);
        NotificationEntity saved = jpaRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<Notification> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Notification> findByIdAndRecipientUserId(Long id, UUID recipientUserId) {
        return jpaRepository.findById(id)
                .filter(n -> n.getRecipientUserId().equals(recipientUserId))
                .map(mapper::toDomain);
    }

    @Override
    public Page<Notification> findByRecipientUserId(UUID recipientUserId, Pageable pageable) {
        return jpaRepository.findByRecipientUserIdOrderByCreatedAtDesc(recipientUserId, pageable).map(mapper::toDomain);
    }

    @Override
    public long countUnreadByRecipientUserId(UUID recipientUserId) {
        return jpaRepository.countByRecipientUserIdAndIsReadFalse(recipientUserId);
    }

    @Override
    @Transactional
    public void markAllAsRead(UUID recipientUserId) {
        jpaRepository.markAllAsRead(recipientUserId, OffsetDateTime.now());
    }

    @Override
    @Transactional
    public void deleteReadOlderThan(OffsetDateTime threshold) {
        jpaRepository.deleteReadOlderThan(threshold);
    }
}

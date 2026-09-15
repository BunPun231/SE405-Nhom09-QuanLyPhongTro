package com.roomrental.modules.notification.infrastructure.adapter;

import com.roomrental.modules.notification.domain.model.NotificationOutbox;
import com.roomrental.modules.notification.domain.repository.NotificationOutboxRepository;
import com.roomrental.modules.notification.infrastructure.mapper.NotificationOutboxMapper;
import com.roomrental.modules.notification.infrastructure.persistence.NotificationOutboxEntity;
import com.roomrental.modules.notification.infrastructure.persistence.NotificationOutboxJpaRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class NotificationOutboxRepositoryAdapter implements NotificationOutboxRepository {

    private final NotificationOutboxJpaRepository jpaRepository;
    private final NotificationOutboxMapper mapper;

    public NotificationOutboxRepositoryAdapter(NotificationOutboxJpaRepository jpaRepository, NotificationOutboxMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    @Transactional
    public NotificationOutbox save(NotificationOutbox outbox) {
        NotificationOutboxEntity entity = mapper.toEntity(outbox);
        NotificationOutboxEntity saved = jpaRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<NotificationOutbox> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public List<NotificationOutbox> findPendingAndRetryable(int maxRetries, int limit) {
        return jpaRepository.findPendingAndRetryable(maxRetries, PageRequest.of(0, limit))
                .stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }
}

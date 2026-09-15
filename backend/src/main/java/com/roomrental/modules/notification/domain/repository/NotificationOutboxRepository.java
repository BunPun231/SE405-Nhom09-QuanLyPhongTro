package com.roomrental.modules.notification.domain.repository;

import com.roomrental.modules.notification.domain.model.NotificationOutbox;
import java.util.List;
import java.util.Optional;

public interface NotificationOutboxRepository {
    NotificationOutbox save(NotificationOutbox outbox);
    Optional<NotificationOutbox> findById(Long id);
    List<NotificationOutbox> findPendingAndRetryable(int maxRetries, int limit);
}

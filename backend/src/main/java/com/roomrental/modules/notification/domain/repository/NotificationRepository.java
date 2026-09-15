package com.roomrental.modules.notification.domain.repository;

import com.roomrental.modules.notification.domain.model.Notification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

public interface NotificationRepository {
    Notification save(Notification notification);
    Optional<Notification> findById(Long id);
    Optional<Notification> findByIdAndRecipientUserId(Long id, UUID recipientUserId);
    Page<Notification> findByRecipientUserId(UUID recipientUserId, Pageable pageable);
    long countUnreadByRecipientUserId(UUID recipientUserId);
    void markAllAsRead(UUID recipientUserId);
    void deleteReadOlderThan(OffsetDateTime threshold);
}

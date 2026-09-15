package com.roomrental.modules.notification.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.modules.notification.domain.model.Notification;
import com.roomrental.modules.notification.domain.repository.NotificationRepository;
import com.roomrental.modules.notification.interfaces.rest.dto.NotificationResult;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class NotificationQueryService {

    private final NotificationRepository notificationRepository;

    public NotificationQueryService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Transactional(readOnly = true)
    public Page<NotificationResult> getNotificationsForUser(UUID userId, Pageable pageable) {
        return notificationRepository.findByRecipientUserId(userId, pageable)
                .map(NotificationResult::fromDomain);
    }

    @Transactional(readOnly = true)
    public long countUnread(UUID userId) {
        return notificationRepository.countUnreadByRecipientUserId(userId);
    }

    @Transactional(rollbackFor = Exception.class)
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllAsRead(userId);
    }

    @Transactional(rollbackFor = Exception.class)
    public NotificationResult markAsRead(Long id, UUID userId) {
        Notification notification = notificationRepository.findByIdAndRecipientUserId(id, userId)
                .orElseThrow(() -> BaseException.notFound("Notification", id));

        notification.markAsRead();
        Notification saved = notificationRepository.save(notification);
        return NotificationResult.fromDomain(saved);
    }
}

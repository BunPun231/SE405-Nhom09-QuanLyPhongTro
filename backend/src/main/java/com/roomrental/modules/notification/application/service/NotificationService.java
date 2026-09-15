package com.roomrental.modules.notification.application.service;

import com.roomrental.modules.notification.domain.model.Notification;
import com.roomrental.modules.notification.domain.model.NotificationOutbox;
import com.roomrental.modules.notification.domain.model.NotificationType;
import com.roomrental.modules.notification.domain.repository.NotificationOutboxRepository;
import com.roomrental.modules.notification.domain.repository.NotificationRepository;
import com.roomrental.modules.notification.interfaces.rest.dto.NotificationResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final NotificationOutboxRepository outboxRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(
            NotificationRepository notificationRepository,
            NotificationOutboxRepository outboxRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.outboxRepository = outboxRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional(rollbackFor = Exception.class)
    public Notification createNotification(UUID tenantId, UUID recipientUserId, String title, String content, NotificationType type, String actionUrl) {
        log.info("Creating notification for user: {}, type: {}", recipientUserId, type);

        // 1. Create and save notification
        Notification notification = new Notification(tenantId, recipientUserId, title, content, type, actionUrl);
        Notification saved = notificationRepository.save(notification);

        // 2. Create and save outbox record for async push (Transactional Outbox Pattern)
        NotificationOutbox outbox = new NotificationOutbox(tenantId, recipientUserId, title, content, type.name(), actionUrl);
        outboxRepository.save(outbox);

        // 3. Realtime WebSocket push
        sendRealtimeWebSocketNotification(recipientUserId, saved);

        return saved;
    }

    private void sendRealtimeWebSocketNotification(UUID userId, Notification notification) {
        try {
            String destination = "/queue/notifications-" + userId.toString();
            NotificationResult result = NotificationResult.fromDomain(notification);
            messagingTemplate.convertAndSend(destination, result);
            log.debug("Realtime notification sent to WebSocket destination: {}", destination);
        } catch (Exception e) {
            log.error("Failed to send realtime WebSocket notification to user: " + userId, e);
        }
    }
}

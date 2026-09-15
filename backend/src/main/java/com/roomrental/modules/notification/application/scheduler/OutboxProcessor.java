package com.roomrental.modules.notification.application.scheduler;

import com.roomrental.modules.notification.domain.model.DeviceToken;
import com.roomrental.modules.notification.domain.model.NotificationOutbox;
import com.roomrental.modules.notification.domain.repository.DeviceTokenRepository;
import com.roomrental.modules.notification.domain.repository.NotificationOutboxRepository;
import com.roomrental.modules.notification.application.service.PushNotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class OutboxProcessor {

    private static final Logger log = LoggerFactory.getLogger(OutboxProcessor.class);

    private final NotificationOutboxRepository outboxRepository;
    private final DeviceTokenRepository deviceTokenRepository;
    private final PushNotificationService pushNotificationService;

    public OutboxProcessor(
            NotificationOutboxRepository outboxRepository,
            DeviceTokenRepository deviceTokenRepository,
            PushNotificationService pushNotificationService) {
        this.outboxRepository = outboxRepository;
        this.deviceTokenRepository = deviceTokenRepository;
        this.pushNotificationService = pushNotificationService;
    }

    @Scheduled(fixedDelay = 60000)
    @Transactional(rollbackFor = Exception.class)
    public void processOutbox() {
        log.debug("OutboxProcessor running to scan for pending push notifications...");
        List<NotificationOutbox> pending = outboxRepository.findPendingAndRetryable(3, 50);
        if (pending.isEmpty()) {
            return;
        }

        log.info("Found {} pending push notification tasks to deliver.", pending.size());
        for (NotificationOutbox outbox : pending) {
            try {
                outbox.markProcessing();
                outboxRepository.save(outbox);

                List<DeviceToken> tokens = deviceTokenRepository.findByUserId(outbox.getRecipientUserId());
                if (tokens.isEmpty()) {
                    // No device tokens registered for this user, mark as sent since we cannot push.
                    log.debug("No FCM device tokens found for user: {}, marking outbox task as SENT", outbox.getRecipientUserId());
                    outbox.markSent();
                    outboxRepository.save(outbox);
                    continue;
                }

                Map<String, String> data = new HashMap<>();
                data.put("type", outbox.getType());
                if (outbox.getActionUrl() != null) {
                    data.put("actionUrl", outbox.getActionUrl());
                }

                boolean anySuccess = false;
                for (DeviceToken dt : tokens) {
                    try {
                        pushNotificationService.sendPushNotification(
                                dt.getToken(),
                                outbox.getTitle(),
                                outbox.getContent(),
                                data
                        );
                        anySuccess = true;
                    } catch (Exception e) {
                        log.error("FCM push delivery failed for token: {}", dt.getToken(), e);
                        String errorMsg = e.getMessage() != null ? e.getMessage().toLowerCase() : "";
                        if (errorMsg.contains("registration-token-not-registered") ||
                            errorMsg.contains("invalid-registration-token") ||
                            errorMsg.contains("invalid-argument") ||
                            errorMsg.contains("not-registered")) {
                            log.warn("FCM token is invalid or unregistered. Deleting from repository: {}", dt.getToken());
                            deviceTokenRepository.deleteByToken(dt.getToken());
                        }
                    }
                }

                if (anySuccess) {
                    outbox.markSent();
                    log.info("Successfully pushed outbox notification ID: {} to user tokens", outbox.getId());
                } else {
                    outbox.markFailed("All FCM pushes failed for user: " + outbox.getRecipientUserId());
                    log.warn("FCM delivery failed for all tokens of user: {}", outbox.getRecipientUserId());
                }
                outboxRepository.save(outbox);

            } catch (Exception e) {
                log.error("Failed to process notification outbox item ID: {}", outbox.getId(), e);
                outbox.markFailed(e.getMessage());
                outboxRepository.save(outbox);
            }
        }
    }
}

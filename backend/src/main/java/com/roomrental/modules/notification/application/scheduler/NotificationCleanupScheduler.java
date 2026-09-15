package com.roomrental.modules.notification.application.scheduler;

import com.roomrental.modules.notification.domain.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Component
public class NotificationCleanupScheduler {

    private static final Logger log = LoggerFactory.getLogger(NotificationCleanupScheduler.class);

    private final NotificationRepository notificationRepository;

    public NotificationCleanupScheduler(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Scheduled(cron = "0 0 3 * * ?")
    @Transactional(rollbackFor = Exception.class)
    public void cleanupOldReadNotifications() {
        log.info("Starting daily read notification cleanup scheduler at 3 AM...");
        try {
            OffsetDateTime threshold = OffsetDateTime.now().minusDays(30);
            notificationRepository.deleteReadOlderThan(threshold);
            log.info("Notification cleanup completed successfully.");
        } catch (Exception e) {
            log.error("Error occurred while cleaning up old read notifications", e);
        }
    }
}

package com.roomrental.modules.notification.infrastructure.persistence;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.UUID;

@Repository
public interface NotificationJpaRepository extends JpaRepository<NotificationEntity, Long> {
    Page<NotificationEntity> findByRecipientUserIdOrderByCreatedAtDesc(UUID recipientUserId, Pageable pageable);

    long countByRecipientUserIdAndIsReadFalse(UUID recipientUserId);

    @Modifying
    @Query("UPDATE NotificationEntity n SET n.isRead = true, n.readAt = :now WHERE n.recipientUserId = :userId AND n.isRead = false")
    void markAllAsRead(@Param("userId") UUID userId, @Param("now") OffsetDateTime now);

    @Modifying
    @Query("DELETE FROM NotificationEntity n WHERE n.isRead = true AND n.createdAt < :threshold")
    void deleteReadOlderThan(@Param("threshold") OffsetDateTime threshold);
}

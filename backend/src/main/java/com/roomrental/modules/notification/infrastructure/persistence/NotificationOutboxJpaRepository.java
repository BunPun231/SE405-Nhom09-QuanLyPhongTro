package com.roomrental.modules.notification.infrastructure.persistence;

import com.roomrental.modules.notification.domain.model.NotificationOutbox.OutboxStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationOutboxJpaRepository extends JpaRepository<NotificationOutboxEntity, Long> {
    
    @Query("SELECT n FROM NotificationOutboxEntity n WHERE n.status = 'PENDING' OR (n.status = 'FAILED' AND n.retryCount < :maxRetries) ORDER BY n.createdAt ASC")
    List<NotificationOutboxEntity> findPendingAndRetryable(@Param("maxRetries") int maxRetries, Pageable pageable);
}

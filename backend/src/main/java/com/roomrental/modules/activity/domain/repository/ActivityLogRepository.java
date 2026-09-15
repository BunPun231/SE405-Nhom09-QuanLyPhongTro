package com.roomrental.modules.activity.domain.repository;

import com.roomrental.modules.activity.domain.model.ActivityLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;

public interface ActivityLogRepository {
    ActivityLog save(ActivityLog activityLog);
    Page<ActivityLog> findAll(com.roomrental.modules.activity.application.dto.ActivityLogFilter filter, Pageable pageable);
    Optional<ActivityLog> findById(Long id);
}

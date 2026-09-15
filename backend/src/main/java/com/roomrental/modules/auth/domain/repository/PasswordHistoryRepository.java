package com.roomrental.modules.auth.domain.repository;

import com.roomrental.modules.auth.domain.model.PasswordHistory;
import java.util.List;
import java.util.UUID;

public interface PasswordHistoryRepository {
    PasswordHistory save(PasswordHistory history);
    List<PasswordHistory> findRecentByUserId(UUID userId, int limit);
}

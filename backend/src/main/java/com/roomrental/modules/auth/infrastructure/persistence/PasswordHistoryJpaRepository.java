package com.roomrental.modules.auth.infrastructure.persistence;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PasswordHistoryJpaRepository extends JpaRepository<PasswordHistoryEntity, Long> {
    List<PasswordHistoryEntity> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
}

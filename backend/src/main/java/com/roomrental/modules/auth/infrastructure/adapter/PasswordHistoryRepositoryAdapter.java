package com.roomrental.modules.auth.infrastructure.adapter;

import com.roomrental.modules.auth.domain.model.PasswordHistory;
import com.roomrental.modules.auth.domain.repository.PasswordHistoryRepository;
import com.roomrental.modules.auth.infrastructure.mapper.PasswordHistoryMapper;
import com.roomrental.modules.auth.infrastructure.persistence.PasswordHistoryEntity;
import com.roomrental.modules.auth.infrastructure.persistence.PasswordHistoryJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class PasswordHistoryRepositoryAdapter implements PasswordHistoryRepository {
    private final PasswordHistoryJpaRepository jpaRepository;
    private final PasswordHistoryMapper mapper;

    @Override
    public PasswordHistory save(PasswordHistory history) {
        PasswordHistoryEntity entity = mapper.toEntity(history);
        if (entity.getCreatedAt() == null) {
            entity.setCreatedAt(java.time.OffsetDateTime.now());
        }
        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public List<PasswordHistory> findRecentByUserId(UUID userId, int limit) {
        return jpaRepository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, limit))
                .stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }
}

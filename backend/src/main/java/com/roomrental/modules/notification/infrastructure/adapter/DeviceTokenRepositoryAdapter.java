package com.roomrental.modules.notification.infrastructure.adapter;

import com.roomrental.modules.notification.domain.model.DeviceToken;
import com.roomrental.modules.notification.domain.repository.DeviceTokenRepository;
import com.roomrental.modules.notification.infrastructure.mapper.DeviceTokenMapper;
import com.roomrental.modules.notification.infrastructure.persistence.DeviceTokenEntity;
import com.roomrental.modules.notification.infrastructure.persistence.DeviceTokenJpaRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class DeviceTokenRepositoryAdapter implements DeviceTokenRepository {

    private final DeviceTokenJpaRepository jpaRepository;
    private final DeviceTokenMapper mapper;

    public DeviceTokenRepositoryAdapter(DeviceTokenJpaRepository jpaRepository, DeviceTokenMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    @Transactional
    public DeviceToken save(DeviceToken deviceToken) {
        DeviceTokenEntity entity = mapper.toEntity(deviceToken);
        DeviceTokenEntity saved = jpaRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public List<DeviceToken> findByUserId(UUID userId) {
        return jpaRepository.findByUserId(userId).stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public Optional<DeviceToken> findByToken(String token) {
        return jpaRepository.findByToken(token).map(mapper::toDomain);
    }

    @Override
    @Transactional
    public void deleteByToken(String token) {
        jpaRepository.deleteByToken(token);
    }
}

package com.roomrental.modules.auth.infrastructure.adapter;

import com.roomrental.modules.auth.domain.model.User;
import com.roomrental.modules.auth.domain.repository.UserRepository;
import com.roomrental.modules.auth.infrastructure.mapper.AuthPersistenceMapper;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
public class UserRepositoryAdapter implements UserRepository {

    private final UserJpaRepository jpa;
    private final AuthPersistenceMapper mapper;

    public UserRepositoryAdapter(UserJpaRepository jpa, AuthPersistenceMapper mapper) {
        this.jpa = jpa;
        this.mapper = mapper;
    }

    @Override
    public User save(User user) {
        return mapper.toDomain(jpa.save(mapper.toEntity(user)));
    }

    @Override
    public Optional<User> findById(UUID id) {
        return jpa.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByPhone(String phone) {
        return jpa.findByPhone(phone).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return jpa.findByEmail(email).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByPhoneOrEmail(String phone, String email) {
        return jpa.findByPhoneOrEmail(phone, email).map(mapper::toDomain);
    }

    @Override
    public boolean existsByPhone(String phone) {
        return jpa.existsByPhone(phone);
    }

    @Override
    public boolean existsByEmail(String email) {
        return jpa.existsByEmail(email);
    }
}

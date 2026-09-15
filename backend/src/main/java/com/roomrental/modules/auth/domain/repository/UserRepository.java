package com.roomrental.modules.auth.domain.repository;

import com.roomrental.modules.auth.domain.model.User;

import java.util.Optional;
import java.util.UUID;

/**
 * Port for User persistence — implemented by infrastructure adapter.
 */
public interface UserRepository {

    User save(User user);

    Optional<User> findById(UUID id);

    Optional<User> findByPhone(String phone);

    Optional<User> findByEmail(String email);

    Optional<User> findByPhoneOrEmail(String phone, String email);

    boolean existsByPhone(String phone);

    boolean existsByEmail(String email);
}

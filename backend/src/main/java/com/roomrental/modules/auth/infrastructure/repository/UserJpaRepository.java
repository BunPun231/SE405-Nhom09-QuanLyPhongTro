package com.roomrental.modules.auth.infrastructure.repository;

import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface UserJpaRepository extends JpaRepository<UserEntity, UUID> {

    Optional<UserEntity> findByPhone(String phone);

    Optional<UserEntity> findByEmail(String email);

    @Query("SELECT u FROM UserEntity u WHERE u.phone = :phone OR u.email = :email")
    Optional<UserEntity> findByPhoneOrEmail(@Param("phone") String phone, @Param("email") String email);

    boolean existsByPhone(String phone);

    boolean existsByEmail(String email);

    Page<UserEntity> findByTenantIdAndRole(UUID tenantId, String role, Pageable pageable);
}

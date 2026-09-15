package com.roomrental.modules.auth.infrastructure.mapper;

import com.roomrental.modules.auth.domain.model.Tenant;
import com.roomrental.modules.auth.domain.model.TenantStatus;
import com.roomrental.modules.auth.domain.model.User;
import com.roomrental.modules.auth.domain.model.UserRole;
import com.roomrental.modules.auth.domain.model.UserStatus;
import com.roomrental.modules.auth.infrastructure.entity.TenantEntity;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

/**
 * MapStruct mapper for converting between Auth domain models and JPA entities.
 */
@Mapper(componentModel = "spring")
public interface AuthPersistenceMapper {

    // ── User ─────────────────────────────────────────────────────────

    @Mapping(target = "role", source = "role", qualifiedByName = "roleToString")
    @Mapping(target = "status", source = "status", qualifiedByName = "statusToString")
    UserEntity toEntity(User user);

    @Mapping(target = "role", source = "role", qualifiedByName = "stringToRole")
    @Mapping(target = "status", source = "status", qualifiedByName = "stringToStatus")
    User toDomain(UserEntity entity);

    // ── Tenant ───────────────────────────────────────────────────────

    @Mapping(target = "status", source = "status", qualifiedByName = "tenantStatusToString")
    TenantEntity toEntity(Tenant tenant);

    @Mapping(target = "status", source = "status", qualifiedByName = "stringToTenantStatus")
    Tenant toDomain(TenantEntity entity);

    // ── Enum converters ──────────────────────────────────────────────

    @Named("roleToString")
    default String roleToString(UserRole role) {
        return role == null ? null : role.name();
    }

    @Named("stringToRole")
    default UserRole stringToRole(String role) {
        return role == null ? null : UserRole.valueOf(role);
    }

    @Named("statusToString")
    default String statusToString(UserStatus status) {
        return status == null ? null : status.name();
    }

    @Named("stringToStatus")
    default UserStatus stringToStatus(String status) {
        return status == null ? null : UserStatus.valueOf(status);
    }

    @Named("tenantStatusToString")
    default String tenantStatusToString(TenantStatus status) {
        return status == null ? null : status.name();
    }

    @Named("stringToTenantStatus")
    default TenantStatus stringToTenantStatus(String status) {
        return status == null ? null : TenantStatus.valueOf(status);
    }
}

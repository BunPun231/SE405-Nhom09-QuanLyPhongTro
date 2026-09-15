package com.roomrental.modules.auth.infrastructure.mapper;

import com.roomrental.modules.auth.domain.model.PasswordHistory;
import com.roomrental.modules.auth.infrastructure.persistence.PasswordHistoryEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface PasswordHistoryMapper {
    PasswordHistory toDomain(PasswordHistoryEntity entity);
    PasswordHistoryEntity toEntity(PasswordHistory domain);
}

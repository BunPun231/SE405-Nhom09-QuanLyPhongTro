package com.roomrental.modules.auth.domain.model;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
public class PasswordHistory {
    private Long id;
    private UUID userId;
    private String passwordHash;
    private OffsetDateTime createdAt;
}

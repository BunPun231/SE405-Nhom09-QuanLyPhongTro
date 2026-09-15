package com.roomrental.modules.auth.application.service;

import com.roomrental.modules.auth.domain.model.PasswordHistory;
import com.roomrental.modules.auth.domain.repository.PasswordHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PasswordHistoryService {
    private final PasswordHistoryRepository passwordHistoryRepository;
    private final PasswordEncoder passwordEncoder;

    public void save(UUID userId, String passwordHash) {
        PasswordHistory history = PasswordHistory.builder()
                .userId(userId)
                .passwordHash(passwordHash)
                .build();
        passwordHistoryRepository.save(history);
    }

    public boolean isPasswordReused(UUID userId, String rawPassword) {
        List<PasswordHistory> recentPasswords = passwordHistoryRepository.findRecentByUserId(userId, 5);
        for (PasswordHistory history : recentPasswords) {
            if (passwordEncoder.matches(rawPassword, history.getPasswordHash())) {
                return true;
            }
        }
        return false;
    }
}

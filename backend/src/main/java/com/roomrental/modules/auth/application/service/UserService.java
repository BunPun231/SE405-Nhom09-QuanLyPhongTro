package com.roomrental.modules.auth.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.exception.BaseException;
import com.roomrental.modules.auth.application.dto.ManagerResponse;
import com.roomrental.modules.auth.application.dto.UserProfileResponse;
import com.roomrental.modules.auth.domain.model.Tenant;
import com.roomrental.modules.auth.domain.model.User;
import com.roomrental.modules.auth.domain.model.UserRole;
import com.roomrental.modules.auth.domain.model.UserStatus;
import com.roomrental.modules.auth.domain.repository.TenantRepository;
import com.roomrental.modules.auth.domain.repository.UserRepository;
import com.roomrental.modules.auth.interfaces.rest.dto.UpdateProfileRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final TenantRepository tenantRepository;

    public UserService(UserRepository userRepository, TenantRepository tenantRepository) {
        this.userRepository = userRepository;
        this.tenantRepository = tenantRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> BaseException.notFound("User", userId));
        return mapToProfileResponse(user);
    }

    @Transactional
    public UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> BaseException.notFound("User", userId));

        if (request.email() != null && !request.email().isBlank()) {
            String newEmail = request.email().trim().toLowerCase(Locale.ROOT);
            if (!newEmail.equalsIgnoreCase(user.getEmail())) {
                if (userRepository.existsByEmailAndIdNot(newEmail, userId)) {
                    throw new BaseException(HttpStatus.CONFLICT, "EMAIL_EXISTS", "Email is already registered by another user");
                }
                user.setEmail(newEmail);
            }
        }

        if (request.phone() != null && !request.phone().isBlank()) {
            String newPhone = request.phone().trim();
            if (!newPhone.equals(user.getPhone())) {
                if (userRepository.existsByPhoneAndIdNot(newPhone, userId)) {
                    throw new BaseException(HttpStatus.CONFLICT, "PHONE_EXISTS", "Phone number is already registered by another user");
                }
                user.setPhone(newPhone);
            }
        }

        if (request.fullName() != null && !request.fullName().isBlank()) {
            user.setFullName(request.fullName().trim());
        }

        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl().trim());
        }

        User saved = userRepository.save(user);
        return mapToProfileResponse(saved);
    }

    @Transactional(readOnly = true)
    public PageResponse<ManagerResponse> getManagers(String search, UserStatus status, Pageable pageable) {
        Page<User> page = userRepository.findAllManagers(
                search != null ? search.trim() : null,
                status,
                pageable
        );

        return PageResponse.from(page, user -> {
            String tenantName = null;
            if (user.getTenantId() != null) {
                tenantName = tenantRepository.findById(user.getTenantId())
                        .map(Tenant::getName)
                        .orElse(null);
            }
            return new ManagerResponse(
                    user.getId(),
                    user.getTenantId(),
                    tenantName,
                    user.getPhone(),
                    user.getEmail(),
                    user.getFullName(),
                    user.getAvatarUrl(),
                    user.getStatus(),
                    user.getLockReason(),
                    user.getCreatedAt(),
                    user.getLastLoginAt()
            );
        });
    }

    @Transactional
    public UserProfileResponse updateManagerStatus(UUID managerId, UserStatus newStatus, String lockReason) {
        User user = userRepository.findById(managerId)
                .orElseThrow(() -> BaseException.notFound("User", managerId));

        if (user.getRole() != UserRole.MANAGER) {
            throw new BaseException(HttpStatus.BAD_REQUEST, "INVALID_ROLE", "User is not a manager");
        }

        user.setStatus(newStatus);
        user.setLockReason(newStatus == UserStatus.LOCKED ? lockReason : null);

        if (newStatus == UserStatus.LOCKED) {
            user.setSessionVersion(user.getSessionVersion() == null ? 1 : user.getSessionVersion() + 1);
        }

        User saved = userRepository.save(user);
        return mapToProfileResponse(saved);
    }

    private UserProfileResponse mapToProfileResponse(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getTenantId(),
                user.getPhone(),
                user.getEmail(),
                user.getFullName(),
                user.getAvatarUrl(),
                user.getRole(),
                user.getStatus(),
                user.isMustChangePassword(),
                user.isHasCompletedOnboarding(),
                user.getCreatedAt(),
                user.getUpdatedAt(),
                user.getLastLoginAt()
        );
    }
}

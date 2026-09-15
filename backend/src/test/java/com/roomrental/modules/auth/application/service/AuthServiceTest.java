package com.roomrental.modules.auth.application.service;

import com.roomrental.common.exception.BaseException;
import com.roomrental.common.security.JwtTokenService;
import com.roomrental.modules.auth.application.dto.AuthResult;
import com.roomrental.modules.auth.application.dto.LoginCommand;
import com.roomrental.modules.auth.application.dto.RegisterCommand;
import com.roomrental.modules.auth.domain.model.*;
import com.roomrental.modules.auth.domain.repository.TenantRepository;
import com.roomrental.modules.auth.domain.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthService Unit Tests")
class AuthServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private TenantRepository tenantRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtTokenService jwtTokenService;
    @Mock private PasswordHistoryService passwordHistoryService;
    @Mock private org.springframework.data.redis.core.StringRedisTemplate redisTemplate;
    @Mock private org.springframework.context.ApplicationEventPublisher eventPublisher;
    @InjectMocks private AuthService authService;

    private User activeUser;
    private Tenant activeTenant;

    @BeforeEach
    void setUp() {
        org.springframework.data.redis.core.ValueOperations valueOperations = mock(org.springframework.data.redis.core.ValueOperations.class);
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        activeUser = new User();
        activeUser.setId(UUID.randomUUID());
        activeUser.setPhone("0901234567");
        activeUser.setEmail("user@test.com");
        activeUser.setFullName("Test User");
        activeUser.setPasswordHash("hashed");
        activeUser.setRole(UserRole.MANAGER);
        activeUser.setStatus(UserStatus.ACTIVE);
        activeUser.setMustChangePassword(false);

        activeTenant = new Tenant();
        activeTenant.setId(UUID.randomUUID());
        activeTenant.setName("Test Tenant");
        activeTenant.setOwnerUserId(activeUser.getId());
        activeTenant.setStatus(TenantStatus.TRIAL);

        activeUser.setTenantId(activeTenant.getId());
    }

    @Nested
    @DisplayName("UC01: Register Manager")
    class RegisterManagerTests {

        @Test
        @DisplayName("Should register successfully with valid data")
        void registerManager_success() {
            when(userRepository.existsByPhone(anyString())).thenReturn(false);
            when(passwordEncoder.encode(anyString())).thenReturn("hashed");
            when(userRepository.save(any(User.class))).thenAnswer(inv -> {
                User u = inv.getArgument(0);
                u.setId(UUID.randomUUID());
                return u;
            });
            when(tenantRepository.save(any(Tenant.class))).thenAnswer(inv -> {
                Tenant t = inv.getArgument(0);
                t.setId(UUID.randomUUID());
                return t;
            });
            when(jwtTokenService.generateToken(any(UUID.class), anyMap())).thenReturn("jwt-token");

            AuthResult result = authService.registerManager(new RegisterCommand(
                    "New Tenant", "Manager", "0909999888", "mgr@test.com", "Pass1234"));

            assertThat(result).isNotNull();
            assertThat(result.accessToken()).isEqualTo("jwt-token");
            assertThat(result.tokenType()).isEqualTo("Bearer");
            assertThat(result.role()).isEqualTo("MANAGER");
            verify(userRepository, times(2)).save(any(User.class));
            verify(tenantRepository).save(any(Tenant.class));
        }

        @Test
        @DisplayName("Should fail when phone already exists")
        void registerManager_phoneExists() {
            when(userRepository.existsByPhone("0901234567")).thenReturn(true);

            assertThatThrownBy(() -> authService.registerManager(
                    new RegisterCommand("T", "N", "0901234567", null, "pw")))
                    .isInstanceOf(BaseException.class)
                    .hasMessageContaining("Phone number is already registered");
        }

        @Test
        @DisplayName("Should fail when email already exists")
        void registerManager_emailExists() {
            when(userRepository.existsByPhone(anyString())).thenReturn(false);
            when(userRepository.existsByEmail("dup@test.com")).thenReturn(true);

            assertThatThrownBy(() -> authService.registerManager(
                    new RegisterCommand("T", "N", "0901111111", "dup@test.com", "pw")))
                    .isInstanceOf(BaseException.class)
                    .hasMessageContaining("Email is already registered");
        }
    }

    @Nested
    @DisplayName("UC02: Login")
    class LoginTests {

        @Test
        @DisplayName("Should login successfully with phone")
        void login_byPhone_success() {
            when(userRepository.findByPhoneOrEmail("0901234567", "0901234567"))
                    .thenReturn(Optional.of(activeUser));
            when(passwordEncoder.matches("Pass1234", "hashed")).thenReturn(true);
            when(tenantRepository.findById(activeTenant.getId())).thenReturn(Optional.of(activeTenant));
            when(jwtTokenService.generateToken(any(UUID.class), anyMap())).thenReturn("jwt-token");

            AuthResult result = authService.login(new LoginCommand("0901234567", "Pass1234"));

            assertThat(result.accessToken()).isEqualTo("jwt-token");
            assertThat(result.userId()).isEqualTo(activeUser.getId());
            verify(userRepository).save(any(User.class)); // update last login
        }

        @Test
        @DisplayName("Should fail with wrong password")
        void login_wrongPassword() {
            when(userRepository.findByPhoneOrEmail("0901234567", "0901234567"))
                    .thenReturn(Optional.of(activeUser));
            when(passwordEncoder.matches("wrong", "hashed")).thenReturn(false);

            assertThatThrownBy(() -> authService.login(new LoginCommand("0901234567", "wrong")))
                    .isInstanceOf(BaseException.class)
                    .hasMessageContaining("Invalid credentials");
        }

        @Test
        @DisplayName("Should fail with non-existent user")
        void login_userNotFound() {
            when(userRepository.findByPhoneOrEmail(anyString(), anyString()))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> authService.login(new LoginCommand("0900000000", "pw")))
                    .isInstanceOf(BaseException.class);
        }

        @Test
        @DisplayName("Should fail when account is locked")
        void login_accountLocked() {
            activeUser.setStatus(UserStatus.LOCKED);
            when(userRepository.findByPhoneOrEmail(anyString(), anyString()))
                    .thenReturn(Optional.of(activeUser));
            when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);

            assertThatThrownBy(() -> authService.login(new LoginCommand("0901234567", "Pass1234")))
                    .isInstanceOf(BaseException.class)
                    .hasMessageContaining("locked");
        }
    }
}

package com.roomrental.modules.auth.infrastructure.bootstrap;

import com.roomrental.common.config.AppProperties;
import com.roomrental.modules.auth.infrastructure.entity.TenantEntity;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import com.roomrental.modules.auth.infrastructure.repository.TenantJpaRepository;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Seeds the default Admin account and tenant on first startup.
 * Skipped if the admin phone already exists.
 */
@Component
public class AdminAccountSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(AdminAccountSeeder.class);

    private final AppProperties appProperties;
    private final UserJpaRepository userJpaRepository;
    private final TenantJpaRepository tenantJpaRepository;
    private final PasswordEncoder passwordEncoder;

    public AdminAccountSeeder(
            AppProperties appProperties,
            UserJpaRepository userJpaRepository,
            TenantJpaRepository tenantJpaRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.appProperties = appProperties;
        this.userJpaRepository = userJpaRepository;
        this.tenantJpaRepository = tenantJpaRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        AppProperties.Admin admin = appProperties.bootstrap().admin();
        if (!admin.enabled()) {
            log.info("Admin bootstrap is disabled");
            return;
        }

        if (userJpaRepository.existsByPhone(admin.phone())) {
            log.info("Admin account already exists, skipping seed");
            return;
        }

        // Create admin user
        UserEntity user = new UserEntity();
        user.setPhone(admin.phone());
        user.setEmail(admin.email());
        user.setFullName(admin.fullName());
        user.setPasswordHash(passwordEncoder.encode(admin.password()));
        user.setRole("ADMIN");
        user.setStatus("ACTIVE");
        user.setMustChangePassword(false);
        user = userJpaRepository.save(user);

        // Create admin tenant workspace
        TenantEntity tenant = new TenantEntity();
        tenant.setName(admin.tenantName());
        tenant.setOwnerUserId(user.getId());
        tenant.setStatus("ACTIVE");
        tenant = tenantJpaRepository.save(tenant);

        // Link user to tenant
        user.setTenantId(tenant.getId());
        userJpaRepository.save(user);

        log.info("Admin account seeded: phone={}, tenantId={}", admin.phone(), tenant.getId());
    }
}

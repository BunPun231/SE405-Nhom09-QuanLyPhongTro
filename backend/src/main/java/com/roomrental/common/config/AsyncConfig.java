package com.roomrental.common.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import com.roomrental.common.util.TenantContext;

import java.util.concurrent.Executor;

/**
 * Async configuration for event-driven logging.
 * Provides a dedicated thread pool for log writing to avoid blocking the main thread.
 */
@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(200);
        executor.setThreadNamePrefix("task-async-");
        executor.setTaskDecorator(runnable -> {
            SecurityContext securityContext = SecurityContextHolder.getContext();
            String tenantId = TenantContext.getCurrentTenantId();
            return () -> {
                SecurityContext previousSecurityContext = SecurityContextHolder.getContext();
                String previousTenantId = TenantContext.getCurrentTenantId();
                try {
                    SecurityContextHolder.setContext(securityContext);
                    if (tenantId != null) {
                        TenantContext.setCurrentTenantId(tenantId);
                    }
                    runnable.run();
                } finally {
                    SecurityContextHolder.setContext(previousSecurityContext);
                    if (previousTenantId == null) {
                        TenantContext.clear();
                    } else {
                        TenantContext.setCurrentTenantId(previousTenantId);
                    }
                }
            };
        });
        executor.setRejectedExecutionHandler(new java.util.concurrent.ThreadPoolExecutor.CallerRunsPolicy());
        executor.initialize();
        return executor;
    }

    @Bean(name = "loggingExecutor")
    public Executor loggingExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(4);
        executor.setQueueCapacity(500);
        executor.setThreadNamePrefix("log-async-");
        executor.setRejectedExecutionHandler(new java.util.concurrent.ThreadPoolExecutor.CallerRunsPolicy());
        executor.initialize();
        return executor;
    }
}

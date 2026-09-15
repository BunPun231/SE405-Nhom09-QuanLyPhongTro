package com.roomrental.config;

import com.roomrental.common.config.AppProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Global application configuration — enables typed config properties.
 */
@Configuration
@EnableConfigurationProperties(AppProperties.class)
public class ApplicationConfig {
}

package com.roomrental.common.security;

import com.roomrental.common.config.AppProperties;
import org.springframework.stereotype.Component;

@Component
public class AesCryptoKeyInitializer {

    public AesCryptoKeyInitializer(AppProperties appProperties) {
        String rawKey = appProperties.security().encryptionKey();
        if (rawKey == null || rawKey.isBlank()) {
            throw new IllegalStateException("app.security.encryption-key must be configured");
        }
        AesCryptoConverter.setSecretKey(rawKey);
    }
}

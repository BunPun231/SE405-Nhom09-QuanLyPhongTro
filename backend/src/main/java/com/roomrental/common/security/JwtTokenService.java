package com.roomrental.common.security;

import com.roomrental.common.config.AppProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtTokenService {

    private final SecretKey secretKey;
    private final long accessTokenMinutes;
    private final long refreshTokenDays;

    public JwtTokenService(AppProperties appProperties) {
        this.secretKey = Keys.hmacShaKeyFor(deriveKeyBytes(appProperties.security().jwtSecret()));
        this.accessTokenMinutes = appProperties.security().accessTokenMinutes();
        this.refreshTokenDays = appProperties.security().refreshTokenDays();
    }

    private byte[] deriveKeyBytes(String secret) {
        if (secret == null || secret.isBlank()) {
            throw new IllegalStateException("JWT secret is required");
        }

        try {
            return MessageDigest.getInstance("SHA-256").digest(secret.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("Unable to derive JWT signing key", ex);
        }
    }

    public String generateToken(UUID subject, Map<String, Object> claims) {
        Instant now = Instant.now();
        Instant expiresAt = now.plusSeconds(accessTokenMinutes * 60);

        return Jwts.builder()
                .subject(subject.toString())
                .claims(claims)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiresAt))
                .signWith(secretKey)
                .compact();
    }

    public String generateRefreshToken(UUID subject) {
        Instant now = Instant.now();
        Instant expiresAt = now.plusSeconds(refreshTokenDays * 24 * 60 * 60);

        return Jwts.builder()
                .subject(subject.toString())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiresAt))
                .signWith(secretKey)
                .compact();
    }

    public long getRefreshTokenDays() {
        return refreshTokenDays;
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}

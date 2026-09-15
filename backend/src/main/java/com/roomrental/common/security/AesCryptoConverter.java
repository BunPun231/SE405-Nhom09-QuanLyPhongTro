package com.roomrental.common.security;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.Base64;
import java.util.concurrent.atomic.AtomicReference;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

@Converter
public class AesCryptoConverter implements AttributeConverter<String, String> {

    private static final int GCM_TAG_LENGTH_BITS = 128;
    private static final int IV_LENGTH_BYTES = 12;
    private static final AtomicReference<SecretKey> SECRET_KEY = new AtomicReference<>();
    private static final AtomicReference<byte[]> IV_SALT = new AtomicReference<>();

    static void setSecretKey(String rawSecret) {
        if (rawSecret == null || rawSecret.isBlank()) {
            throw new IllegalStateException("PII encryption key is missing");
        }
        SECRET_KEY.set(deriveKey(rawSecret));
        IV_SALT.set(deriveIvSalt(rawSecret));
    }

    private static SecretKey getSecretKey() {
        SecretKey key = SECRET_KEY.get();
        if (key == null) {
            throw new IllegalStateException("PII encryption key has not been initialized");
        }
        return key;
    }

    private static byte[] getIvSalt() {
        byte[] salt = IV_SALT.get();
        if (salt == null) {
            throw new IllegalStateException("PII encryption key has not been initialized");
        }
        return salt;
    }

    private static SecretKey deriveKey(String rawSecret) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] keyBytes = digest.digest(rawSecret.getBytes(StandardCharsets.UTF_8));
            return new SecretKeySpec(keyBytes, "AES");
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to derive AES key", ex);
        }
    }

    private static byte[] deriveIvSalt(String rawSecret) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return digest.digest(rawSecret.getBytes(StandardCharsets.UTF_8));
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to derive AES IV salt", ex);
        }
    }

    private static byte[] deriveDeterministicIv(String attribute) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(getIvSalt());
            digest.update(attribute.getBytes(StandardCharsets.UTF_8));
            byte[] full = digest.digest();
            return Arrays.copyOf(full, IV_LENGTH_BYTES);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to derive deterministic IV", ex);
        }
    }

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null) {
            return null;
        }
        try {
            byte[] iv = deriveDeterministicIv(attribute);

            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, getSecretKey(), new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] cipherText = cipher.doFinal(attribute.getBytes(StandardCharsets.UTF_8));

            String ivEncoded = Base64.getEncoder().encodeToString(iv);
            String cipherEncoded = Base64.getEncoder().encodeToString(cipherText);
            return ivEncoded + ":" + cipherEncoded;
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to encrypt PII field", ex);
        }
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null) {
            return null;
        }
        if (!looksLikeEncryptedPayload(dbData)) {
            return dbData;
        }
        try {
            String[] parts = dbData.split(":", 2);
            if (parts.length != 2) {
                throw new IllegalStateException("Invalid encrypted PII payload");
            }
            byte[] iv = Base64.getDecoder().decode(parts[0]);
            byte[] cipherText = Base64.getDecoder().decode(parts[1]);

            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, getSecretKey(), new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] plainText = cipher.doFinal(cipherText);
            return new String(plainText, StandardCharsets.UTF_8);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to decrypt PII field", ex);
        }
    }

    private boolean looksLikeEncryptedPayload(String dbData) {
        String[] parts = dbData.split(":", 2);
        if (parts.length != 2) {
            return false;
        }
        try {
            Base64.getDecoder().decode(parts[0]);
            Base64.getDecoder().decode(parts[1]);
            return true;
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }
}

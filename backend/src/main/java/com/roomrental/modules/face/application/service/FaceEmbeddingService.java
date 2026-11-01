package com.roomrental.modules.face.application.service;

import com.roomrental.modules.face.domain.model.FaceRecord;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class FaceEmbeddingService {

    private final Map<String, FaceRecord> facesByUser = new ConcurrentHashMap<>();

    public FaceRecord register(String userId, String name, List<Double> embedding) {
        if (userId == null || userId.isBlank()) {
            throw new IllegalArgumentException("userId is required");
        }
        if (embedding == null || embedding.isEmpty()) {
            throw new IllegalArgumentException("embedding must not be empty");
        }

        final String normalizedUserId = userId.trim();
        final String normalizedName = (name == null || name.isBlank()) ? "Unknown" : name.trim();
        final List<Double> normalizedEmbedding = embedding.stream()
                .filter(java.util.Objects::nonNull)
                .map(value -> value.doubleValue())
                .toList();

        if (normalizedEmbedding.isEmpty()) {
            throw new IllegalArgumentException("embedding must not be empty");
        }

        FaceRecord faceRecord = new FaceRecord(
                UUID.randomUUID().toString(),
                normalizedUserId,
                normalizedName,
                normalizedEmbedding,
                Instant.now()
        );

        facesByUser.put(normalizedUserId, faceRecord);
        return faceRecord;
    }

    public List<FaceRecord> getAll() {
        return new ArrayList<>(facesByUser.values());
    }
}

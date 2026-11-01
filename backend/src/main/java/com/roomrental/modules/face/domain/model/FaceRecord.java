package com.roomrental.modules.face.domain.model;

import java.time.Instant;
import java.util.List;

public record FaceRecord(
        String id,
        String userId,
        String name,
        List<Double> embedding,
        Instant createdAt
) {
}

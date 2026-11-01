package com.roomrental.modules.face.interfaces.rest.dto;

import com.roomrental.modules.face.domain.model.FaceRecord;

import java.time.Instant;
import java.util.List;

public record FaceRecordResponse(
        String id,
        String userId,
        String name,
        List<Double> embedding,
        Instant createdAt
) {
    public static FaceRecordResponse from(FaceRecord record) {
        return new FaceRecordResponse(
                record.id(),
                record.userId(),
                record.name(),
                record.embedding(),
                record.createdAt()
        );
    }
}

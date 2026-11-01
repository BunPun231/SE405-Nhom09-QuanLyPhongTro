package com.roomrental.modules.face.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.modules.face.application.service.FaceEmbeddingService;
import com.roomrental.modules.face.domain.model.FaceRecord;
import com.roomrental.modules.face.interfaces.rest.dto.FaceRecordResponse;
import com.roomrental.modules.face.interfaces.rest.dto.FaceRegisterRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@Tag(name = "Face Recognition", description = "Face embedding registration and sync endpoints")
public class FaceController {

    private final FaceEmbeddingService faceEmbeddingService;

    public FaceController(FaceEmbeddingService faceEmbeddingService) {
        this.faceEmbeddingService = faceEmbeddingService;
    }

    @PostMapping({"/faces/register", "/faces"})
    @Operation(summary = "Register or update a face embedding")
    public ResponseEntity<ApiResponse<FaceRecordResponse>> registerFace(@Valid @RequestBody FaceRegisterRequest request) {
        FaceRecord record = faceEmbeddingService.register(request.userId(), request.name(), request.embedding());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(FaceRecordResponse.from(record), "Face registered successfully"));
    }

    @GetMapping({"/faces", "/faces/registered", "/faces/list"})
    @Operation(summary = "Get all registered face embeddings")
    public ResponseEntity<ApiResponse<List<FaceRecordResponse>>> getFaces() {
        List<FaceRecordResponse> payload = faceEmbeddingService.getAll().stream()
                .map(FaceRecordResponse::from)
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(payload, "Face list loaded successfully"));
    }
}

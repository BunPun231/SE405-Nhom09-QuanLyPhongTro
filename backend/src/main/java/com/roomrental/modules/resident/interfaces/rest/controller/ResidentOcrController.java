package com.roomrental.modules.resident.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.modules.finance.infrastructure.adapter.GeminiOcrAdapter;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Base64;
import java.util.Map;

@RestController
@RequestMapping("/api/residents/ocr")
@Tag(name = "Resident OCR", description = "ID card OCR prefill endpoints")
public class ResidentOcrController {

    private final GeminiOcrAdapter geminiOcrAdapter;

    public ResidentOcrController(GeminiOcrAdapter geminiOcrAdapter) {
        this.geminiOcrAdapter = geminiOcrAdapter;
    }

    public static record OcrIdRequest(String base64Image, String mimeType) {}

    @PostMapping("/idcard")
    @Operation(summary = "Extract CCCD fields from image and return JSON prefill")
    public ResponseEntity<ApiResponse<Map<String, Object>>> extractIdCard(@Valid @RequestBody OcrIdRequest body) {
        byte[] bytes = Base64.getDecoder().decode(body.base64Image());
        String json = geminiOcrAdapter.extractIdCardJson(bytes, body.mimeType());
        // return parsed JSON as map
        try {
            Map<String, Object> map = new com.fasterxml.jackson.databind.ObjectMapper().readValue(json, Map.class);
            return ResponseEntity.ok(ApiResponse.ok(map));
        } catch (Exception e) {
            throw new RuntimeException("Invalid OCR JSON: " + e.getMessage(), e);
        }
    }
}

package com.roomrental.modules.finance.infrastructure.adapter;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.common.exception.BaseException;
import com.roomrental.modules.finance.domain.port.OcrPort;
import com.roomrental.modules.finance.domain.port.OcrResult;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@ConditionalOnProperty(name = "app.ocr.provider", havingValue = "GEMINI")
public class GeminiOcrAdapter implements OcrPort {

    @Value("${app.gemini.api-key:}")
    private String apiKey;

    @Value("${app.gemini.model:gemini-3-flash}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcrResult extractReading(byte[] imageBytes, String mimeType) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            throw BaseException.badRequest("Gemini API key is not configured in environment (GEMINI_API_KEY)");
        }

        try {
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            // Construct payload structure for Gemini API
            Map<String, Object> inlineData = new HashMap<>();
            inlineData.put("mimeType", mimeType != null ? mimeType : "image/jpeg");
            inlineData.put("data", base64Image);

            Map<String, Object> textPart = new HashMap<>();
            textPart.put("text", "Read the water/electricity meter reading value from the image. Return a clean JSON object with a single key 'reading' and the extracted numeric value as the value. Example: {\"reading\": 1234}.");

            Map<String, Object> imagePart = new HashMap<>();
            imagePart.put("inlineData", inlineData);

            Map<String, Object> content = new HashMap<>();
            content.put("parts", List.of(textPart, imagePart));

            // JSON Schema properties configuration
            Map<String, Object> readingProp = new HashMap<>();
            readingProp.put("type", "NUMBER");

            Map<String, Object> responseSchema = new HashMap<>();
            responseSchema.put("type", "OBJECT");
            responseSchema.put("properties", Map.of("reading", readingProp));
            responseSchema.put("required", List.of("reading"));

            Map<String, Object> generationConfig = new HashMap<>();
            generationConfig.put("responseMimeType", "application/json");
            generationConfig.put("responseSchema", responseSchema);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("contents", List.of(content));
            requestBody.put("generationConfig", generationConfig);

            // Build request
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = String.format("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, apiKey);

            String responseStr = restTemplate.postForObject(url, entity, String.class);

            // Parse response
            JsonNode root = objectMapper.readTree(responseStr);
            JsonNode textNode = root.path("candidates")
                    .path(0)
                    .path("content")
                    .path("parts")
                    .path(0)
                    .path("text");

            if (textNode.isMissingNode() || textNode.asText().isEmpty()) {
                throw BaseException.badRequest("Gemini did not return any OCR suggestion");
            }

            String jsonText = textNode.asText();
            JsonNode readingJson = objectMapper.readTree(jsonText);
            JsonNode readingNode = readingJson.path("reading");

            if (readingNode.isMissingNode()) {
                throw BaseException.badRequest("Gemini response is missing the 'reading' field. Raw: " + jsonText);
            }

            BigDecimal readingVal = new BigDecimal(readingNode.asText());
            double confidence = 95.0; // Standard high confidence with schema validation

            return new OcrResult(readingVal, confidence, jsonText);
        } catch (Exception e) {
            e.printStackTrace();
            throw BaseException.badRequest("Failed to extract reading from image via Gemini: " + e.getMessage());
        }
    }

    /**
     * Specialized OCR extraction for Vietnamese CCCD / ID cards.
     * Returns a clean JSON string containing keys: idNumber, fullName, dateOfBirth, address
     */
    public String extractIdCardJson(byte[] imageBytes, String mimeType) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            throw BaseException.badRequest("Gemini API key is not configured in environment (GEMINI_API_KEY)");
        }

        try {
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            Map<String, Object> inlineData = new HashMap<>();
            inlineData.put("mimeType", mimeType != null ? mimeType : "image/jpeg");
            inlineData.put("data", base64Image);

            Map<String, Object> textPart = new HashMap<>();
            // System prompt tailored for Vietnamese CCCD
            String prompt = "You are an OCR assistant specialized in reading Vietnamese CCCD (citizen ID) cards. " +
                    "Extract and return a strict JSON object with exactly these keys: idNumber, fullName, dateOfBirth, address. " +
                    "Normalize dateOfBirth to YYYY-MM-DD. Clean whitespace, remove extraneous characters, and prefer the printed ID number if present. " +
                    "If any field cannot be confidently extracted, return an empty string for that field. " +
                    "Respond only with a JSON object, no extra text. Example: {\"idNumber\":\"079123456789\",\"fullName\":\"Nguyen Van A\",\"dateOfBirth\":\"1990-01-01\",\"address\":\"123 Le Loi, District 1, HCMC\"}.";
            textPart.put("text", prompt);

            Map<String, Object> imagePart = new HashMap<>();
            imagePart.put("inlineData", inlineData);

            Map<String, Object> content = new HashMap<>();
            content.put("parts", List.of(textPart, imagePart));

            Map<String, Object> stringProp = new HashMap<>();
            stringProp.put("type", "STRING");

            Map<String, Object> responseSchema = new HashMap<>();
            responseSchema.put("type", "OBJECT");
            responseSchema.put("properties", Map.of(
                    "idNumber", stringProp,
                    "fullName", stringProp,
                    "dateOfBirth", stringProp,
                    "address", stringProp
            ));
            responseSchema.put("required", List.of("idNumber", "fullName"));

            Map<String, Object> generationConfig = new HashMap<>();
            generationConfig.put("responseMimeType", "application/json");
            generationConfig.put("responseSchema", responseSchema);

            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("contents", List.of(content));
            requestBody.put("generationConfig", generationConfig);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = String.format("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, apiKey);

            String responseStr = restTemplate.postForObject(url, entity, String.class);
            JsonNode root = objectMapper.readTree(responseStr);
            JsonNode textNode = root.path("candidates").path(0).path("content").path("parts").path(0).path("text");
            if (textNode.isMissingNode() || textNode.asText().isEmpty()) {
                throw BaseException.badRequest("Gemini did not return any OCR suggestion for ID card");
            }
            String jsonText = textNode.asText();
            // Basic validation: ensure it's JSON object
            JsonNode parsed = objectMapper.readTree(jsonText);
            if (!parsed.isObject()) {
                throw BaseException.badRequest("Gemini returned invalid JSON for ID card OCR");
            }
            return objectMapper.writeValueAsString(parsed);
        } catch (Exception e) {
            e.printStackTrace();
            throw BaseException.badRequest("Failed to extract ID card from image via Gemini: " + e.getMessage());
        }
    }
}

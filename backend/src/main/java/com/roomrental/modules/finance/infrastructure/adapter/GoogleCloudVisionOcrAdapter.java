package com.roomrental.modules.finance.infrastructure.adapter;

import com.google.cloud.vision.v1.*;
import com.google.protobuf.ByteString;
import com.roomrental.modules.finance.domain.port.OcrPort;
import com.roomrental.modules.finance.domain.port.OcrResult;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
@ConditionalOnProperty(name = "app.ocr.provider", havingValue = "GOOGLE_VISION")
public class GoogleCloudVisionOcrAdapter implements OcrPort {

    @Override
    public OcrResult extractReading(byte[] imageBytes, String mimeType) {
        try {
            ByteString imgBytes = ByteString.copyFrom(imageBytes);
            Image img = Image.newBuilder().setContent(imgBytes).build();
            Feature feat = Feature.newBuilder().setType(Feature.Type.TEXT_DETECTION).build();
            AnnotateImageRequest request = AnnotateImageRequest.newBuilder()
                    .addFeatures(feat)
                    .setImage(img)
                    .build();

            List<AnnotateImageRequest> requests = new ArrayList<>();
            requests.add(request);

            try (ImageAnnotatorClient client = ImageAnnotatorClient.create()) {
                BatchAnnotateImagesResponse response = client.batchAnnotateImages(requests);
                List<AnnotateImageResponse> responses = response.getResponsesList();

                if (responses.isEmpty() || responses.get(0).hasError()) {
                    return new OcrResult(null, 0.0, "");
                }

                String rawText = responses.get(0).getTextAnnotationsList().get(0).getDescription();
                
                // Trích xuất số bằng Regex
                Pattern pattern = Pattern.compile("\\d+[.,]?\\d*");
                Matcher matcher = pattern.matcher(rawText);
                
                BigDecimal extractedValue = null;
                double confidence = 85.0; // Simulated confidence if regex matches
                
                // For simplicity we just pick the largest or last number found, or the first.
                // In real app, we might do more advanced heuristics. Here we take the first valid number.
                if (matcher.find()) {
                    String numberStr = matcher.group().replace(",", ".");
                    extractedValue = new BigDecimal(numberStr);
                } else {
                    confidence = 0.0;
                }

                return new OcrResult(extractedValue, confidence, rawText);
            }
        } catch (Exception e) {
            e.printStackTrace();
            // Log exception in real world
            return new OcrResult(null, 0.0, e.getMessage());
        }
    }
}

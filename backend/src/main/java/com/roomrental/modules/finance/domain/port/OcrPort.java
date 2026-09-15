package com.roomrental.modules.finance.domain.port;

public interface OcrPort {
    OcrResult extractReading(byte[] imageBytes, String mimeType);
}

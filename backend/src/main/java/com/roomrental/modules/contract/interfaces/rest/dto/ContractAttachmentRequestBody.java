package com.roomrental.modules.contract.interfaces.rest.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;

/**
 * Request DTO dinh kem ban scan / mau hop dong (US63.3).
 */
public record ContractAttachmentRequestBody(
        @Schema(description = "Ten tep", example = "hop-dong-trang-1.jpg") String fileName,
        @NotBlank @Schema(description = "Noi dung anh dang base64") String base64Data
) {
}

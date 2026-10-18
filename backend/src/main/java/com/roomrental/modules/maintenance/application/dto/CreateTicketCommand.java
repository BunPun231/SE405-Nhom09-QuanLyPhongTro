package com.roomrental.modules.maintenance.application.dto;

import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.UUID;

public record CreateTicketCommand(
        Long roomId,
        String category,
        String description,
        String priority,
        List<MultipartFile> beforeImageFiles
) {}

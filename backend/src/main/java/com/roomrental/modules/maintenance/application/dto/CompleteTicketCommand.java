package com.roomrental.modules.maintenance.application.dto;

import org.springframework.web.multipart.MultipartFile;
import java.util.List;

public record CompleteTicketCommand(
        List<UsedDeviceItem> usedDevices,
        String note,
        List<MultipartFile> afterImageFiles
) {}

package com.roomrental.modules.maintenance.interfaces.rest.dto;

import com.roomrental.modules.maintenance.application.dto.UsedDeviceItem;
import java.util.List;

public record CompleteTicketRequest(
        List<UsedDeviceItem> usedDevices,
        String note
) {}

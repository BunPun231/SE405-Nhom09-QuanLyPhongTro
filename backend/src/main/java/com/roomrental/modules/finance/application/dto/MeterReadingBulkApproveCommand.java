package com.roomrental.modules.finance.application.dto;

import java.util.List;

public record MeterReadingBulkApproveCommand(
    List<Long> ids
) {}

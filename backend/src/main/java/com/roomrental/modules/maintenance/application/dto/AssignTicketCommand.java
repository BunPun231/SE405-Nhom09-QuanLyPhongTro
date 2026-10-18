package com.roomrental.modules.maintenance.application.dto;

import java.util.UUID;

public record AssignTicketCommand(
        UUID technicianId
) {}

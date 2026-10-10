package com.roomrental.modules.maintenance.interfaces.rest.dto;

import java.util.UUID;

public record AssignTicketRequest(
        UUID technicianId
) {}

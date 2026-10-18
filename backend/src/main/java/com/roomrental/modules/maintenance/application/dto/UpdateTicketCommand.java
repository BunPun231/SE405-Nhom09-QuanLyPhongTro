package com.roomrental.modules.maintenance.application.dto;

public record UpdateTicketCommand(
        String category,
        String description,
        String priority
) {}

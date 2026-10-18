package com.roomrental.modules.maintenance.interfaces.rest.dto;

public record UpdateTicketRequest(
        String category,
        String description,
        String priority
) {}

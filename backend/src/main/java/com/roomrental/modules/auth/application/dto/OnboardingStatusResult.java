package com.roomrental.modules.auth.application.dto;

public record OnboardingStatusResult(
    boolean hasCompletedOnboarding,
    boolean hasMotel,
    boolean hasSePayConfig,
    boolean hasRooms,
    boolean hasActiveContract,
    boolean hasMeterReadings,
    boolean hasInvoice,
    int currentStep
) {}

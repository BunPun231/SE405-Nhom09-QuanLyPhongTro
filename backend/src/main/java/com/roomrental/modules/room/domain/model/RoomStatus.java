package com.roomrental.modules.room.domain.model;

/**
 * Room availability statuses.
 * Matches DB CHECK constraint on rooms.status.
 */
public enum RoomStatus {
    EMPTY,
    DEPOSITED,
    RENTED,
    REPAIRING,
    OUT_OF_BUSINESS
}

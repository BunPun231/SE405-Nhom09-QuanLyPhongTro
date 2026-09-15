package com.roomrental.modules.room.domain.repository;

import com.roomrental.modules.room.domain.model.Room;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.Optional;

/**
 * Port for Room persistence.
 */
public interface RoomRepository {

    Room save(Room room);

    Optional<Room> findById(Long id);

    Optional<Room> findByIdAndMotelId(Long id, Long motelId);

    Page<Room> findByMotelId(Long motelId, Pageable pageable);

    boolean existsByMotelIdAndRoomNumber(Long motelId, String roomNumber);
}

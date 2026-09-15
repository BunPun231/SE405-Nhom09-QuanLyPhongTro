package com.roomrental.modules.room.infrastructure.adapter;

import com.roomrental.modules.room.domain.model.Room;
import com.roomrental.modules.room.domain.repository.RoomRepository;
import com.roomrental.modules.room.infrastructure.mapper.RoomPersistenceMapper;
import com.roomrental.modules.room.infrastructure.repository.RoomJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class RoomRepositoryAdapter implements RoomRepository {

    private final RoomJpaRepository jpa;
    private final RoomPersistenceMapper mapper;

    public RoomRepositoryAdapter(RoomJpaRepository jpa, RoomPersistenceMapper mapper) {
        this.jpa = jpa;
        this.mapper = mapper;
    }

    @Override
    public Room save(Room room) {
        return mapper.toDomain(jpa.save(mapper.toEntity(room)));
    }

    @Override
    public Optional<Room> findById(Long id) {
        return jpa.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Room> findByIdAndMotelId(Long id, Long motelId) {
        return jpa.findByIdAndMotelId(id, motelId).map(mapper::toDomain);
    }

    @Override
    public Page<Room> findByMotelId(Long motelId, Pageable pageable) {
        return jpa.findByMotelId(motelId, pageable).map(mapper::toDomain);
    }

    @Override
    public boolean existsByMotelIdAndRoomNumber(Long motelId, String roomNumber) {
        return jpa.existsByMotelIdAndRoomNumber(motelId, roomNumber);
    }
}

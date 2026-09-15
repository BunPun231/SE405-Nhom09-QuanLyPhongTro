package com.roomrental.modules.service.infrastructure.adapter;

import com.roomrental.modules.service.domain.model.RentalService;
import com.roomrental.modules.service.domain.repository.RentalServiceRepository;
import com.roomrental.modules.service.infrastructure.mapper.ServicePersistenceMapper;
import com.roomrental.modules.service.infrastructure.repository.ServiceJpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
public class ServiceRepositoryAdapter implements RentalServiceRepository {

    private final ServiceJpaRepository jpa;
    private final ServicePersistenceMapper mapper;

    public ServiceRepositoryAdapter(ServiceJpaRepository jpa, ServicePersistenceMapper mapper) {
        this.jpa = jpa;
        this.mapper = mapper;
    }

    @Override
    public RentalService save(RentalService service) {
        return mapper.toDomain(jpa.save(mapper.toEntity(service)));
    }

    @Override
    public Optional<RentalService> findByIdAndMotelId(Long id, Long motelId) {
        return jpa.findByIdAndMotelId(id, motelId).map(mapper::toDomain);
    }

    @Override
    public Optional<RentalService> findById(Long id) {
        return jpa.findById(id).map(mapper::toDomain);
    }

    @Override
    public Page<RentalService> findByMotelId(Long motelId, Pageable pageable) {
        return jpa.findByMotelId(motelId, pageable).map(mapper::toDomain);
    }

    @Override
    public List<RentalService> findByMotelIdAndMandatory(Long motelId, boolean mandatory) {
        return jpa.findByMotelIdAndMandatory(motelId, mandatory).stream()
                .map(mapper::toDomain)
                .collect(Collectors.toList());
    }

    @Override
    public boolean existsByMotelIdAndName(Long motelId, String name) {
        return jpa.existsByMotelIdAndName(motelId, name);
    }
}

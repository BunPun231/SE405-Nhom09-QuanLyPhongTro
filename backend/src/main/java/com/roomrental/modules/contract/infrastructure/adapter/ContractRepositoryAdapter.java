package com.roomrental.modules.contract.infrastructure.adapter;

import com.roomrental.modules.contract.domain.model.Contract;
import com.roomrental.modules.contract.domain.repository.ContractRepository;
import com.roomrental.modules.contract.infrastructure.mapper.ContractMapper;
import com.roomrental.modules.contract.infrastructure.persistence.ContractEntity;
import com.roomrental.modules.contract.infrastructure.persistence.ContractJpaRepository;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

/**
 * Repository Adapter - triển khai domain port ContractRepository.
 * Thích ứng giữa domain layer và Spring Data JPA.
 */
@Component
public class ContractRepositoryAdapter implements ContractRepository {
    private final ContractJpaRepository jpaRepository;
    private final ContractMapper mapper;

    public ContractRepositoryAdapter(ContractJpaRepository jpaRepository, ContractMapper mapper) {
        this.jpaRepository = jpaRepository;
        this.mapper = mapper;
    }

    @Override
    public Contract save(Contract contract) {
        ContractEntity entity = mapper.toEntity(contract);
        ContractEntity saved = jpaRepository.save(entity);
        return mapper.toDomain(saved);
    }

    @Override
    public Optional<Contract> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Contract> findByIdAndTenantId(Long id, UUID tenantId) {
        return jpaRepository.findByIdAndTenantId(id, tenantId).map(mapper::toDomain);
    }

    @Override
    public List<Contract> findByTenantId(UUID tenantId) {
        return jpaRepository.findByTenantId(tenantId).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public Page<Contract> findByTenantIdAndMotelId(UUID tenantId, Long motelId, Pageable pageable) {
        return jpaRepository.findByTenantIdAndMotelId(tenantId, motelId, pageable)
                .map(mapper::toDomain);
    }

    @Override
    public Page<Contract> findByTenantIdAndMotelIdAndStatus(UUID tenantId, Long motelId, String status, Pageable pageable) {
        return jpaRepository.findByTenantIdAndMotelIdAndStatus(tenantId, motelId, status, pageable)
                .map(mapper::toDomain);
    }

    @Override
    public Page<Contract> findExpiringByTenantIdAndMotelId(UUID tenantId, Long motelId, LocalDate fromDate, LocalDate toDate, Pageable pageable) {
        return jpaRepository.findExpiringByTenantIdAndMotelId(tenantId, motelId, fromDate, toDate, pageable)
                .map(mapper::toDomain);
    }

    @Override
    public List<Contract> findByRoomId(Long roomId) {
        return jpaRepository.findByRoomId(roomId).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public List<Contract> findActiveByTenantId(UUID tenantId) {
        return jpaRepository.findActiveByTenantId(tenantId).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public boolean existsActiveByRoomId(UUID tenantId, Long roomId) {
        return jpaRepository.existsActiveByRoomId(tenantId, roomId);
    }

    @Override
    public List<Contract> findByResidentUserId(UUID tenantId, UUID residentUserId) {
        return jpaRepository.findByResidentUserId(tenantId, residentUserId).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public void delete(Long id) {
        jpaRepository.deleteById(id);
    }

    @Override
    public boolean existsById(Long id) {
        return jpaRepository.existsById(id);
    }

    @Override
    public long countByTenantId(UUID tenantId) {
        return jpaRepository.findByTenantId(tenantId).size();
    }

    @Override
    public List<Contract> findAllActiveContractsNative() {
        return jpaRepository.findAllActiveContractsNative().stream()
                .map(mapper::toDomain)
                .toList();
    }
}

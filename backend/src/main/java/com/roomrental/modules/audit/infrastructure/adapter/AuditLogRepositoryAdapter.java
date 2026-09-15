package com.roomrental.modules.audit.infrastructure.adapter;

import com.roomrental.modules.audit.application.dto.AuditLogFilter;
import com.roomrental.modules.audit.domain.model.AuditLog;
import com.roomrental.modules.audit.domain.repository.AuditLogRepository;
import com.roomrental.modules.audit.infrastructure.mapper.AuditLogMapper;
import com.roomrental.modules.audit.infrastructure.persistence.AuditLogEntity;
import com.roomrental.modules.audit.infrastructure.persistence.AuditLogJpaRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class AuditLogRepositoryAdapter implements AuditLogRepository {

    private final AuditLogJpaRepository jpaRepository;
    private final AuditLogMapper mapper;

    @Override
    public AuditLog save(AuditLog auditLog) {
        AuditLogEntity entity = mapper.toEntity(auditLog);
        if (entity.getTimestamp() == null) {
            entity.setTimestamp(java.time.OffsetDateTime.now());
        }
        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public Page<AuditLog> findAll(AuditLogFilter filter, Pageable pageable) {
        Specification<AuditLogEntity> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (filter.actorId() != null) {
                predicates.add(cb.equal(root.get("actorId"), filter.actorId()));
            }
            if (filter.action() != null) {
                predicates.add(cb.equal(root.get("action"), filter.action()));
            }
            if (filter.entityType() != null) {
                predicates.add(cb.equal(root.get("entityType"), filter.entityType()));
            }
            if (filter.fromDate() != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("timestamp"), filter.fromDate()));
            }
            if (filter.toDate() != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("timestamp"), filter.toDate()));
            }
            if (query.getResultType() != Long.class && query.getResultType() != long.class) {
                query.orderBy(cb.desc(root.get("id")));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
        return jpaRepository.findAll(spec, pageable).map(mapper::toDomain);
    }

    @Override
    public Optional<AuditLog> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    public void deleteOlderThan(OffsetDateTime date) {
        jpaRepository.deleteByTimestampBefore(date);
    }
}

package com.roomrental.modules.activity.infrastructure.adapter;

import com.roomrental.modules.activity.application.dto.ActivityLogFilter;
import com.roomrental.modules.activity.domain.model.ActivityLog;
import com.roomrental.modules.activity.domain.repository.ActivityLogRepository;
import com.roomrental.modules.activity.infrastructure.mapper.ActivityLogMapper;
import com.roomrental.modules.activity.infrastructure.persistence.ActivityLogEntity;
import com.roomrental.modules.activity.infrastructure.persistence.ActivityLogJpaRepository;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class ActivityLogRepositoryAdapter implements ActivityLogRepository {

    private final ActivityLogJpaRepository jpaRepository;
    private final ActivityLogMapper mapper;

    @Override
    public ActivityLog save(ActivityLog activityLog) {
        ActivityLogEntity entity = mapper.toEntity(activityLog);
        if (entity.getTimestamp() == null) {
            entity.setTimestamp(java.time.OffsetDateTime.now());
        }
        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    public Page<ActivityLog> findAll(ActivityLogFilter filter, Pageable pageable) {
        Specification<ActivityLogEntity> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            if (filter.tenantId() != null) {
                predicates.add(cb.equal(root.get("tenantId"), filter.tenantId()));
            }
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
    public Optional<ActivityLog> findById(Long id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }
}

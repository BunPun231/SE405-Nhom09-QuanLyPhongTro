package com.roomrental.modules.activity.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface ActivityLogJpaRepository extends JpaRepository<ActivityLogEntity, Long>, JpaSpecificationExecutor<ActivityLogEntity> {
}

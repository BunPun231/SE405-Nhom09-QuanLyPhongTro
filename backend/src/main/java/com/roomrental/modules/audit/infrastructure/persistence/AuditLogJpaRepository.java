package com.roomrental.modules.audit.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;

@Repository
public interface AuditLogJpaRepository extends JpaRepository<AuditLogEntity, Long>, JpaSpecificationExecutor<AuditLogEntity> {
    
    @Modifying
    @Query("DELETE FROM AuditLogEntity a WHERE a.timestamp < :date")
    void deleteByTimestampBefore(OffsetDateTime date);
}

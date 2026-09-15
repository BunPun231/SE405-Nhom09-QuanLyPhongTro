package com.roomrental.modules.resident.infrastructure.repository;

import com.roomrental.modules.resident.infrastructure.entity.ResidentProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.UUID;

public interface ResidentProfileJpaRepository extends JpaRepository<ResidentProfileEntity, UUID> {
    boolean existsByIdCardNumber(String idCardNumber);

    @Query("SELECT COUNT(rp) > 0 FROM ResidentProfileEntity rp JOIN UserEntity u ON rp.userId = u.id WHERE rp.idCardNumber = :idCardNumber AND u.tenantId = :tenantId")
    boolean existsByIdCardNumberAndTenantId(@Param("idCardNumber") String idCardNumber, @Param("tenantId") UUID tenantId);
}

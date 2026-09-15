package com.roomrental.modules.finance.infrastructure.persistence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ResidentBalanceJpaRepository extends JpaRepository<ResidentBalanceEntity, UUID> {
}

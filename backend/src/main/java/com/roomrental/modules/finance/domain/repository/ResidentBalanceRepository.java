package com.roomrental.modules.finance.domain.repository;

import com.roomrental.modules.finance.domain.model.ResidentBalance;
import java.util.Optional;
import java.util.UUID;

public interface ResidentBalanceRepository {
    Optional<ResidentBalance> findById(UUID residentUserId);
    ResidentBalance save(ResidentBalance balance);
}

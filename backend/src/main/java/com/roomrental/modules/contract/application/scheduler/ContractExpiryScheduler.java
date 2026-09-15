package com.roomrental.modules.contract.application.scheduler;

import com.roomrental.modules.contract.infrastructure.persistence.ContractJpaRepository;
import com.roomrental.modules.contract.infrastructure.persistence.ContractEntity;
import com.roomrental.modules.auth.infrastructure.repository.UserJpaRepository;
import com.roomrental.modules.auth.infrastructure.entity.UserEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * UC55: Tự động thu hồi quyền truy cập.
 * Runs daily at midnight to find expired/cancelled contracts and
 * set their primary resident's status to INACTIVE.
 */
@Component
public class ContractExpiryScheduler {

    private static final Logger log = LoggerFactory.getLogger(ContractExpiryScheduler.class);

    private final ContractJpaRepository contractRepository;
    private final UserJpaRepository userRepository;

    public ContractExpiryScheduler(ContractJpaRepository contractRepository,
                                   UserJpaRepository userRepository) {
        this.contractRepository = contractRepository;
        this.userRepository = userRepository;
    }

    /**
     * UC55: Daily job to auto-revoke access for residents whose contracts expired.
     * Runs every day at 00:05 AM.
     * Per SRS BR55: Sets resident status = INACTIVE when no active contract remains.
     */
    @Scheduled(cron = "0 5 0 * * *")
    @Transactional
    public void revokeExpiredContractAccess() {
        LocalDate today = LocalDate.now();
        log.info("[UC55] Running contract expiry check for date: {}", today);

        // Find all contracts that expired yesterday or earlier and are still ACTIVE
        List<ContractEntity> expiredContracts = contractRepository.findAll().stream()
                .filter(c -> "ACTIVE".equals(c.getStatus()) && c.getEndDate() != null
                        && c.getEndDate().isBefore(today))
                .toList();

        int revokedCount = 0;
        for (ContractEntity contract : expiredContracts) {
            // Mark contract as expired-pending liquidation
            contract.setStatus("PENDING_LIQUIDATION");
            contractRepository.save(contract);

            // Deactivate primary resident if no other active contracts remain
            if (contract.getPrimaryResidentUserId() != null) {
                boolean hasOtherActiveContract = contractRepository.findAll().stream()
                        .anyMatch(c -> contract.getPrimaryResidentUserId().equals(c.getPrimaryResidentUserId())
                                && "ACTIVE".equals(c.getStatus())
                                && !c.getId().equals(contract.getId()));

                if (!hasOtherActiveContract) {
                    userRepository.findById(contract.getPrimaryResidentUserId()).ifPresent(user -> {
                        if ("ACTIVE".equals(user.getStatus())) {
                            user.setStatus("INACTIVE");
                            userRepository.save(user);
                            log.info("[UC55] Deactivated resident userId={} for expired contractId={}",
                                    user.getId(), contract.getId());
                        }
                    });
                    revokedCount++;
                }
            }
        }

        log.info("[UC55] Processed {} expired contracts, revoked access for {} residents.",
                expiredContracts.size(), revokedCount);
    }
}

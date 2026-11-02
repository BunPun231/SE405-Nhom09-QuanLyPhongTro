package com.roomrental.modules.resident.application.service;

import com.roomrental.modules.resident.application.event.ResidentAccessRevokedEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * UC55: Automatically revoke a resident's access when their contract ends
 * (status LIQUIDATED or CANCELED).
 * <ul>
 *   <li>Unlinks residents from the room: contract_residents.is_active = false, left_at = now (BR55.2).</li>
 *   <li>If the resident has no other open contract: account status = INACTIVE (login disabled)
 *       and session_version + 1 so every issued JWT is rejected immediately (BR55.3).</li>
 *   <li>The user row is never deleted (BR79) — creating the resident again reactivates it.</li>
 * </ul>
 */
@Slf4j
@Service
public class ResidentAccessRevocationService {

    static final Set<String> ENDED_STATUSES = Set.of("LIQUIDATED", "CANCELED");

    private final NamedParameterJdbcTemplate jdbc;
    private final ApplicationEventPublisher eventPublisher;

    public ResidentAccessRevocationService(NamedParameterJdbcTemplate jdbc,
                                           ApplicationEventPublisher eventPublisher) {
        this.jdbc = jdbc;
        this.eventPublisher = eventPublisher;
    }

    /**
     * Revokes access of every resident of the given contract if the contract has ended.
     *
     * @return number of resident accounts deactivated
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public int revokeForContract(Long contractId, UUID actorId, String actorRole) {
        MapSqlParameterSource p = new MapSqlParameterSource().addValue("cid", contractId);
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT status, tenant_id FROM contracts WHERE id = :cid", p);
        if (rows.isEmpty()) return 0;
        String status = (String) rows.get(0).get("status");
        if (!ENDED_STATUSES.contains(status)) return 0;
        UUID tenantId = (UUID) rows.get(0).get("tenant_id");

        List<UUID> residentIds = jdbc.queryForList("""
                SELECT resident_user_id FROM contract_residents WHERE contract_id = :cid
                UNION
                SELECT primary_resident_user_id FROM contracts WHERE id = :cid
                """, p, UUID.class);

        jdbc.update("""
                UPDATE contract_residents
                SET is_active = FALSE, left_at = COALESCE(left_at, CURRENT_TIMESTAMP)
                WHERE contract_id = :cid AND is_active = TRUE
                """, p);

        int revoked = 0;
        for (UUID residentId : residentIds) {
            MapSqlParameterSource rp = new MapSqlParameterSource()
                    .addValue("uid", residentId)
                    .addValue("cid", contractId);
            Integer openContracts = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM contracts c
                    WHERE c.id <> :cid
                      AND c.status IN ('ACTIVE', 'PENDING_LIQUIDATION', 'DRAFT')
                      AND (c.primary_resident_user_id = :uid
                           OR EXISTS (SELECT 1 FROM contract_residents cr
                                      WHERE cr.contract_id = c.id AND cr.resident_user_id = :uid
                                        AND cr.is_active = TRUE))
                    """, rp, Integer.class);
            if (openContracts != null && openContracts > 0) {
                continue;
            }
            int updated = jdbc.update("""
                    UPDATE users
                    SET status = 'INACTIVE',
                        session_version = COALESCE(session_version, 0) + 1,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = :uid AND role = 'RESIDENT' AND status = 'ACTIVE'
                    """, rp);
            if (updated > 0) {
                revoked++;
                log.info("[UC55] AUTO_REVOKE_ACCESS residentId={} contractId={} status={}",
                        residentId, contractId, status);
                if (actorId != null && tenantId != null) {
                    eventPublisher.publishEvent(new ResidentAccessRevokedEvent(
                            tenantId, actorId, actorRole, residentId, contractId, status));
                }
            }
        }
        return revoked;
    }

    /** Ended contracts that still have an active resident link (safety net for the scheduler). */
    @Transactional(readOnly = true)
    public List<Long> findEndedContractsWithActiveLinks() {
        return jdbc.queryForList("""
                SELECT DISTINCT c.id FROM contracts c
                JOIN contract_residents cr ON cr.contract_id = c.id
                WHERE c.status IN ('LIQUIDATED', 'CANCELED') AND cr.is_active = TRUE
                """, new MapSqlParameterSource(), Long.class);
    }
}

package com.roomrental.modules.resident.application.service;

import com.roomrental.common.dto.PageResponse;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.resident.application.dto.ResidentResult;
import com.roomrental.modules.resident.application.dto.ResidentViews;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * Read-side queries for the Manager's tenant screens (UC50, UC51, UC52, UC54 check).
 * Aggregates resident, contract, room, invoice and maintenance data with tenant isolation
 * (every query is scoped by the current workspace tenantId — BR50.2 / BR52.3).
 */
@Service
public class ResidentQueryService {

    public static final Set<String> LIST_FILTERS =
            Set.of("ALL", "LIVING", "PENDING", "FORMER", "INACTIVE", "DEBT");

    /** All (contract, resident) pairs of the workspace: co-residents + primary resident. */
    private static final String LINKS_CTE = """
            links AS (
                SELECT cr.contract_id AS contract_id, cr.resident_user_id AS uid
                FROM contract_residents cr
                JOIN contracts c0 ON c0.id = cr.contract_id
                WHERE c0.tenant_id = :tenantId
                UNION
                SELECT c1.id, c1.primary_resident_user_id
                FROM contracts c1
                WHERE c1.tenant_id = :tenantId
            )""";

    private static final String DEBT_CTE = """
            debt AS (
                SELECT l.uid,
                       SUM(GREATEST(i.total_amount - i.paid_amount - COALESCE(i.balance_deduction, 0), 0)) AS amt,
                       COUNT(*) AS cnt
                FROM invoices i
                JOIN links l ON l.contract_id = i.contract_id
                WHERE i.status IN ('PENDING', 'PARTIAL') AND COALESCE(i.is_deleted, FALSE) = FALSE
                GROUP BY l.uid
            )""";

    private static final String SUMMARY_BASE = "WITH " + LINKS_CTE + ",\n" + DEBT_CTE + """
            ,
            ranked AS (
                SELECT l.uid, c.id, c.status, c.room_id,
                       ROW_NUMBER() OVER (PARTITION BY l.uid ORDER BY
                           CASE c.status WHEN 'ACTIVE' THEN 0 WHEN 'PENDING_LIQUIDATION' THEN 1
                                         WHEN 'DRAFT' THEN 2 ELSE 3 END,
                           c.start_date DESC, c.id DESC) AS rn
                FROM links l JOIN contracts c ON c.id = l.contract_id
            ),
            base AS (
                SELECT u.id, u.full_name, u.phone, u.email, u.status AS account_status,
                       -- inline base64 images are only returned by the detail API to keep lists light
                       CASE WHEN u.avatar_url LIKE 'http%' THEN u.avatar_url END AS avatar_url,
                       rk.id AS contract_id, rk.status AS contract_status,
                       r.room_number, m.name AS motel_name,
                       CASE WHEN rk.status IN ('ACTIVE', 'PENDING_LIQUIDATION') THEN 'LIVING'
                            WHEN rk.status = 'DRAFT' THEN 'PENDING'
                            WHEN rk.status IS NULL THEN 'NO_CONTRACT'
                            ELSE 'FORMER' END AS residency_status,
                       COALESCE(d.amt, 0) AS debt_amount,
                       COALESCE(d.cnt, 0) AS unpaid_count
                FROM users u
                LEFT JOIN ranked rk ON rk.uid = u.id AND rk.rn = 1
                LEFT JOIN rooms r ON r.id = rk.room_id
                LEFT JOIN motels m ON m.id = r.motel_id
                LEFT JOIN debt d ON d.uid = u.id
                WHERE u.tenant_id = :tenantId AND u.role = 'RESIDENT'
            )
            """;

    private static final String SUMMARY_FILTER = """
            WHERE (:q = '' OR LOWER(t.full_name) LIKE :qLike OR t.phone LIKE :qPhone)
              AND (:status = 'ALL'
                   OR (:status = 'INACTIVE' AND t.account_status = 'INACTIVE')
                   OR (:status = 'DEBT' AND t.debt_amount > 0)
                   OR (:status = 'PENDING' AND t.residency_status IN ('PENDING', 'NO_CONTRACT'))
                   OR (:status IN ('LIVING', 'FORMER') AND t.residency_status = :status))
            """;

    private final NamedParameterJdbcTemplate jdbc;

    public ResidentQueryService(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ------------------------------------------------------------------
    // UC50: search / filter / paginate current tenants
    // ------------------------------------------------------------------
    @Transactional(readOnly = true)
    public PageResponse<ResidentViews.Summary> search(String q, String status, int page, int size) {
        UUID tenantId = SecurityUtils.requireTenantId();
        int safeSize = Math.max(1, Math.min(size, 100));
        int safePage = Math.max(0, page);
        String normalizedStatus = normalizeFilter(status);
        MapSqlParameterSource params = searchParams(tenantId, q)
                .addValue("status", normalizedStatus)
                .addValue("limit", safeSize)
                .addValue("offset", safePage * safeSize);

        Long total = jdbc.queryForObject(
                SUMMARY_BASE + "SELECT COUNT(*) FROM base t " + SUMMARY_FILTER, params, Long.class);
        List<ResidentViews.Summary> rows = jdbc.query(
                SUMMARY_BASE + "SELECT * FROM base t " + SUMMARY_FILTER + """
                        ORDER BY CASE t.residency_status WHEN 'LIVING' THEN 0 WHEN 'PENDING' THEN 1
                                                         WHEN 'NO_CONTRACT' THEN 2 ELSE 3 END,
                                 LOWER(t.full_name), t.id
                        LIMIT :limit OFFSET :offset
                        """,
                params, (rs, i) -> mapSummary(rs));
        long totalElements = total == null ? 0 : total;
        return PageResponse.<ResidentViews.Summary>builder()
                .content(rows)
                .page(safePage)
                .size(safeSize)
                .totalElements(totalElements)
                .totalPages((int) Math.ceil(totalElements / (double) safeSize))
                .build();
    }

    // ------------------------------------------------------------------
    // UC52: historical tenants (moved out), filter by move-out date
    // ------------------------------------------------------------------
    @Transactional(readOnly = true)
    public PageResponse<ResidentViews.History> history(String q, LocalDate from, LocalDate to, int page, int size) {
        UUID tenantId = SecurityUtils.requireTenantId();
        int safeSize = Math.max(1, Math.min(size, 100));
        int safePage = Math.max(0, page);
        MapSqlParameterSource params = searchParams(tenantId, q)
                .addValue("from", from, Types.DATE)
                .addValue("to", to, Types.DATE)
                .addValue("limit", safeSize)
                .addValue("offset", safePage * safeSize);

        String base = "WITH " + LINKS_CTE + ",\n" + DEBT_CTE + """
                ,
                open_uids AS (
                    SELECT DISTINCT l.uid FROM links l JOIN contracts c ON c.id = l.contract_id
                    WHERE c.status IN ('ACTIVE', 'PENDING_LIQUIDATION', 'DRAFT')
                ),
                ended AS (
                    SELECT l.uid, c.id AS contract_id, c.status AS contract_status, c.room_id,
                           c.start_date, c.deposit_amount, c.deposit_status,
                           COALESCE(c.move_out_reason, c.cancel_reason) AS end_reason,
                           COALESCE(c.intended_move_out_date, CAST(c.updated_at AS date), c.end_date) AS out_date
                    FROM links l JOIN contracts c ON c.id = l.contract_id
                    WHERE c.status IN ('LIQUIDATED', 'CANCELED')
                ),
                filtered AS (
                    SELECT e.*, ROW_NUMBER() OVER (PARTITION BY e.uid ORDER BY e.out_date DESC, e.contract_id DESC) AS rn
                    FROM ended e
                    WHERE (CAST(:from AS date) IS NULL OR e.out_date >= CAST(:from AS date))
                      AND (CAST(:to AS date) IS NULL OR e.out_date <= CAST(:to AS date))
                ),
                hist AS (
                    SELECT u.id, u.full_name, u.phone, u.status AS account_status,
                           f.contract_id, f.contract_status, r.room_number, m.name AS motel_name,
                           f.start_date, f.out_date, f.deposit_amount, f.deposit_status, f.end_reason,
                           s.total_amount AS settlement_total, s.paid_amount AS settlement_paid,
                           s.status AS settlement_status, COALESCE(d.amt, 0) AS remaining_debt
                    FROM filtered f
                    JOIN users u ON u.id = f.uid
                    LEFT JOIN rooms r ON r.id = f.room_id
                    LEFT JOIN motels m ON m.id = r.motel_id
                    LEFT JOIN LATERAL (
                        SELECT i.total_amount, i.paid_amount, i.status FROM invoices i
                        WHERE i.contract_id = f.contract_id AND i.invoice_type = 'SETTLEMENT'
                          AND COALESCE(i.is_deleted, FALSE) = FALSE
                        ORDER BY i.id DESC LIMIT 1
                    ) s ON TRUE
                    LEFT JOIN debt d ON d.uid = u.id
                    WHERE f.rn = 1 AND u.tenant_id = :tenantId AND u.role = 'RESIDENT'
                      AND u.id NOT IN (SELECT uid FROM open_uids)
                )
                """;
        String filter = " WHERE (:q = '' OR LOWER(t.full_name) LIKE :qLike OR t.phone LIKE :qPhone) ";

        Long total = jdbc.queryForObject(base + "SELECT COUNT(*) FROM hist t" + filter, params, Long.class);
        List<ResidentViews.History> rows = jdbc.query(
                base + "SELECT * FROM hist t" + filter
                        + " ORDER BY t.out_date DESC NULLS LAST, t.contract_id DESC LIMIT :limit OFFSET :offset",
                params, (rs, i) -> {
                    LocalDate in = rs.getObject("start_date", LocalDate.class);
                    LocalDate out = rs.getObject("out_date", LocalDate.class);
                    return new ResidentViews.History(
                            rs.getObject("id", UUID.class),
                            rs.getString("full_name"),
                            rs.getString("phone"),
                            rs.getString("account_status"),
                            rs.getLong("contract_id"),
                            rs.getString("contract_status"),
                            rs.getString("room_number"),
                            rs.getString("motel_name"),
                            in,
                            out,
                            stayDays(in, out),
                            rs.getBigDecimal("deposit_amount"),
                            rs.getString("deposit_status"),
                            rs.getBigDecimal("settlement_total"),
                            rs.getBigDecimal("settlement_paid"),
                            rs.getString("settlement_status"),
                            rs.getBigDecimal("remaining_debt"),
                            rs.getString("end_reason"));
                });
        long totalElements = total == null ? 0 : total;
        return PageResponse.<ResidentViews.History>builder()
                .content(rows)
                .page(safePage)
                .size(safeSize)
                .totalElements(totalElements)
                .totalPages((int) Math.ceil(totalElements / (double) safeSize))
                .build();
    }

    // ------------------------------------------------------------------
    // UC51: aggregated detail (profile + contracts + payments + history)
    // ------------------------------------------------------------------
    @Transactional(readOnly = true)
    public ResidentViews.Overview overview(ResidentResult profile) {
        UUID tenantId = SecurityUtils.requireTenantId();
        UUID residentId = profile.userId();
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("tenantId", tenantId)
                .addValue("uid", residentId);

        ResidentViews.Summary summary = summaryOf(tenantId, residentId);

        List<ResidentViews.ContractItem> contracts = jdbc.query("WITH " + LINKS_CTE + """
                SELECT c.id, c.status, r.room_number, m.name AS motel_name, c.start_date, c.end_date,
                       CASE WHEN c.status IN ('LIQUIDATED', 'CANCELED')
                            THEN COALESCE(c.intended_move_out_date, CAST(c.updated_at AS date), c.end_date)
                            ELSE c.intended_move_out_date END AS move_out_date,
                       c.rent_price, c.deposit_amount, c.deposit_status,
                       (c.primary_resident_user_id = :uid) AS is_primary
                FROM links l
                JOIN contracts c ON c.id = l.contract_id
                LEFT JOIN rooms r ON r.id = c.room_id
                LEFT JOIN motels m ON m.id = r.motel_id
                WHERE l.uid = :uid
                ORDER BY CASE c.status WHEN 'ACTIVE' THEN 0 WHEN 'PENDING_LIQUIDATION' THEN 1
                                       WHEN 'DRAFT' THEN 2 ELSE 3 END,
                         c.start_date DESC, c.id DESC
                """, params, (rs, i) -> new ResidentViews.ContractItem(
                rs.getLong("id"),
                rs.getString("status"),
                rs.getString("room_number"),
                rs.getString("motel_name"),
                rs.getObject("start_date", LocalDate.class),
                rs.getObject("end_date", LocalDate.class),
                rs.getObject("move_out_date", LocalDate.class),
                rs.getBigDecimal("rent_price"),
                rs.getBigDecimal("deposit_amount"),
                rs.getString("deposit_status"),
                rs.getBoolean("is_primary")));

        List<ResidentViews.InvoiceItem> invoices = jdbc.query("WITH " + LINKS_CTE + """
                SELECT i.id, i.contract_id, r.room_number, i.billing_month, i.due_date,
                       i.total_amount, i.paid_amount,
                       GREATEST(i.total_amount - i.paid_amount - COALESCE(i.balance_deduction, 0), 0) AS remaining,
                       i.status, i.invoice_type
                FROM invoices i
                JOIN links l ON l.contract_id = i.contract_id
                JOIN contracts c ON c.id = i.contract_id
                LEFT JOIN rooms r ON r.id = c.room_id
                WHERE l.uid = :uid AND COALESCE(i.is_deleted, FALSE) = FALSE
                ORDER BY i.billing_month DESC, i.id DESC
                LIMIT 60
                """, params, (rs, i) -> new ResidentViews.InvoiceItem(
                rs.getLong("id"),
                rs.getLong("contract_id"),
                rs.getString("room_number"),
                rs.getObject("billing_month", LocalDate.class),
                rs.getObject("due_date", LocalDate.class),
                rs.getBigDecimal("total_amount"),
                rs.getBigDecimal("paid_amount"),
                rs.getBigDecimal("remaining"),
                rs.getString("status"),
                rs.getString("invoice_type")));

        List<ResidentViews.MaintenanceItem> maintenance = jdbc.query("""
                SELECT t.id, r.room_number, t.category, t.description, t.status, t.priority,
                       t.created_at, t.completed_at
                FROM maintenance_tickets t
                JOIN rooms r ON r.id = t.room_id
                JOIN motels m ON m.id = r.motel_id
                WHERE t.reported_by = :uid AND m.tenant_id = :tenantId
                ORDER BY t.created_at DESC
                LIMIT 50
                """, params, (rs, i) -> new ResidentViews.MaintenanceItem(
                rs.getLong("id"),
                rs.getString("room_number"),
                rs.getString("category"),
                rs.getString("description"),
                rs.getString("status"),
                rs.getString("priority"),
                rs.getObject("created_at", LocalDateTime.class),
                rs.getObject("completed_at", LocalDateTime.class)));

        List<ResidentViews.ActivityItem> activities = jdbc.query("""
                SELECT a.action, a.old_value, a.new_value, CAST(a.metadata AS text) AS metadata, a.timestamp
                FROM activity_logs a
                WHERE a.tenant_id = :tenantId AND a.entity_type = 'Resident'
                  AND a.entity_id = CAST(:uid AS text)
                ORDER BY a.timestamp DESC
                LIMIT 50
                """, params, (rs, i) -> new ResidentViews.ActivityItem(
                rs.getString("action"),
                rs.getString("old_value"),
                rs.getString("new_value"),
                rs.getString("metadata"),
                rs.getObject("timestamp", OffsetDateTime.class)));

        String blockReason = deactivateBlockReason(profile.status(), contracts, summary);
        return new ResidentViews.Overview(
                profile,
                summary != null ? summary.residencyStatus() : "NO_CONTRACT",
                summary != null ? summary.debtAmount() : BigDecimal.ZERO,
                summary != null ? summary.unpaidInvoiceCount() : 0,
                blockReason == null,
                blockReason,
                contracts,
                invoices,
                maintenance,
                activities);
    }

    /** UC49: open contracts (ACTIVE / DRAFT) a new resident can be linked to. */
    @Transactional(readOnly = true)
    public List<ResidentViews.LinkableContract> linkableContracts() {
        UUID tenantId = SecurityUtils.requireTenantId();
        return jdbc.query("""
                SELECT c.id, c.status, r.room_number, m.name AS motel_name, u.full_name AS primary_name,
                       c.start_date, c.end_date
                FROM contracts c
                JOIN rooms r ON r.id = c.room_id
                JOIN motels m ON m.id = r.motel_id
                LEFT JOIN users u ON u.id = c.primary_resident_user_id
                WHERE c.tenant_id = :tenantId AND c.status IN ('ACTIVE', 'DRAFT')
                ORDER BY m.name, r.room_number, c.id DESC
                """, new MapSqlParameterSource("tenantId", tenantId),
                (rs, i) -> new ResidentViews.LinkableContract(
                        rs.getLong("id"),
                        rs.getString("status"),
                        rs.getString("room_number"),
                        rs.getString("motel_name"),
                        rs.getString("primary_name"),
                        rs.getObject("start_date", LocalDate.class),
                        rs.getObject("end_date", LocalDate.class)));
    }

    /**
     * UC54 (BR54.2 / BR54.8): returns null when the resident can be deactivated,
     * otherwise a Vietnamese explanation shown to the Manager.
     */
    @Transactional(readOnly = true)
    public String deactivateBlockReason(UUID residentId, String accountStatus) {
        UUID tenantId = SecurityUtils.requireTenantId();
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("tenantId", tenantId)
                .addValue("uid", residentId);
        List<ResidentViews.ContractItem> open = jdbc.query("WITH " + LINKS_CTE + """
                SELECT c.id, c.status FROM links l JOIN contracts c ON c.id = l.contract_id
                WHERE l.uid = :uid
                """, params, (rs, i) -> new ResidentViews.ContractItem(
                rs.getLong("id"), rs.getString("status"), null, null, null, null, null,
                null, null, null, false));
        return deactivateBlockReason(accountStatus, open, summaryOf(tenantId, residentId));
    }

    static String deactivateBlockReason(String accountStatus,
                                        List<ResidentViews.ContractItem> contracts,
                                        ResidentViews.Summary summary) {
        if ("INACTIVE".equals(accountStatus)) {
            return "Hồ sơ này đã được vô hiệu hóa trước đó.";
        }
        for (ResidentViews.ContractItem c : contracts) {
            if (Set.of("ACTIVE", "PENDING_LIQUIDATION", "DRAFT").contains(c.status())) {
                return "Khách còn hợp đồng #" + c.id() + " chưa thanh lý. "
                        + "Cần tất toán và thanh lý hợp đồng trước khi vô hiệu hóa.";
            }
        }
        if (summary != null && summary.debtAmount() != null
                && summary.debtAmount().compareTo(BigDecimal.ZERO) > 0) {
            return "Khách còn " + summary.unpaidInvoiceCount()
                    + " hóa đơn chưa thanh toán. Cần thu đủ trước khi vô hiệu hóa.";
        }
        return null;
    }

    private ResidentViews.Summary summaryOf(UUID tenantId, UUID residentId) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("tenantId", tenantId)
                .addValue("uid", residentId);
        List<ResidentViews.Summary> rows = jdbc.query(
                SUMMARY_BASE + "SELECT * FROM base t WHERE t.id = :uid", params, (rs, i) -> mapSummary(rs));
        return rows.isEmpty() ? null : rows.get(0);
    }

    private static MapSqlParameterSource searchParams(UUID tenantId, String q) {
        String query = q == null ? "" : q.trim();
        String lower = query.toLowerCase(Locale.ROOT)
                .replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
        String phone = query.replaceAll("[^0-9]", "");
        return new MapSqlParameterSource()
                .addValue("tenantId", tenantId)
                .addValue("q", query)
                .addValue("qLike", "%" + lower + "%")
                // Phone: prefix match (BR50.6); a non-numeric query never matches phones.
                .addValue("qPhone", phone.isEmpty() ? "#no-phone#" : phone + "%");
    }

    static String normalizeFilter(String status) {
        if (status == null) return "ALL";
        String upper = status.trim().toUpperCase(Locale.ROOT);
        return LIST_FILTERS.contains(upper) ? upper : "ALL";
    }

    static long stayDays(LocalDate in, LocalDate out) {
        if (in == null || out == null || out.isBefore(in)) return 0;
        return ChronoUnit.DAYS.between(in, out);
    }

    private static ResidentViews.Summary mapSummary(ResultSet rs) throws SQLException {
        Object contractId = rs.getObject("contract_id");
        return new ResidentViews.Summary(
                rs.getObject("id", UUID.class),
                rs.getString("full_name"),
                rs.getString("phone"),
                rs.getString("email"),
                rs.getString("account_status"),
                rs.getString("avatar_url"),
                contractId == null ? null : ((Number) contractId).longValue(),
                rs.getString("contract_status"),
                rs.getString("room_number"),
                rs.getString("motel_name"),
                rs.getString("residency_status"),
                rs.getBigDecimal("debt_amount"),
                rs.getInt("unpaid_count"));
    }
}

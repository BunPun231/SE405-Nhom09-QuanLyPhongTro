-- Backfill service usages for existing active contract service items.
-- This prevents meter reading inserts from referencing missing service_usage rows
-- in databases that existed before service_usages were auto-created in application code.

INSERT INTO service_usages (
    room_id,
    service_id,
    registered_quantity,
    status,
    registered_at,
    updated_at
)
SELECT
    c.room_id,
    csi.service_id,
    COALESCE(csi.quantity, 1),
    'ACTIVE',
    COALESCE(c.updated_at, c.created_at, CURRENT_TIMESTAMP),
    c.updated_at
FROM contracts c
JOIN contract_service_items csi
    ON csi.contract_id = c.id
WHERE c.status IN ('ACTIVE', 'PENDING_LIQUIDATION')
  AND NOT EXISTS (
      SELECT 1
      FROM service_usages su
      WHERE su.room_id = c.room_id
        AND su.service_id = csi.service_id
  );
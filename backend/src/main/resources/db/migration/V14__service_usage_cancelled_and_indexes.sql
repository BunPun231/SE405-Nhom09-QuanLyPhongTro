ALTER TABLE service_usages
    DROP CONSTRAINT IF EXISTS service_usages_status_check;

ALTER TABLE service_usages
    ADD CONSTRAINT service_usages_status_check
        CHECK (status IN ('ACTIVE', 'PENDING_CANCELLATION', 'CANCELLED'));

CREATE INDEX IF NOT EXISTS idx_service_usages_room_service_status
    ON service_usages (room_id, service_id, status);

CREATE INDEX IF NOT EXISTS idx_service_usages_room_status
    ON service_usages (room_id, status);
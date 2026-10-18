-- Migration V28: Upgrade device_movement_logs to support full audit trail (quantity & actions)
ALTER TABLE device_movement_logs ADD COLUMN IF NOT EXISTS quantity INT NOT NULL DEFAULT 1;

ALTER TABLE device_movement_logs DROP CONSTRAINT IF EXISTS device_movement_logs_action_check;

ALTER TABLE device_movement_logs ADD CONSTRAINT device_movement_logs_action_check
    CHECK (action IN ('ASSIGN', 'RECALL', 'IMPORT', 'DISPOSE', 'MAINTENANCE_USE'));

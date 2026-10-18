-- V30__add_repairing_quantity_and_expand_logs.sql
-- Add repairing_quantity to devices table and expand device_movement_logs actions

ALTER TABLE devices ADD COLUMN repairing_quantity INT NOT NULL DEFAULT 0;

-- Update CHECK constraint for device_movement_logs to include new action
ALTER TABLE device_movement_logs DROP CONSTRAINT IF EXISTS chk_device_movement_logs_action;
ALTER TABLE device_movement_logs ADD CONSTRAINT chk_device_movement_logs_action CHECK (action IN ('ASSIGN', 'RECALL', 'IMPORT', 'DISPOSE', 'MAINTENANCE_USE', 'SEND_TO_REPAIR', 'FINISH_REPAIR'));

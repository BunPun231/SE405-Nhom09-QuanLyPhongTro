-- Migration V31: Drop old action check constraints and add updated one supporting SEND_TO_REPAIR & FINISH_REPAIR
ALTER TABLE device_movement_logs DROP CONSTRAINT IF EXISTS device_movement_logs_action_check;
ALTER TABLE device_movement_logs DROP CONSTRAINT IF EXISTS chk_device_movement_logs_action;
ALTER TABLE device_movement_logs ADD CONSTRAINT device_movement_logs_action_check
    CHECK (action IN ('ASSIGN', 'RECALL', 'IMPORT', 'DISPOSE', 'MAINTENANCE_USE', 'SEND_TO_REPAIR', 'FINISH_REPAIR'));

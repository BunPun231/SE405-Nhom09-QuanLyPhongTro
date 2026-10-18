-- Migration V32: Add snapshot quantity columns to device_movement_logs
ALTER TABLE device_movement_logs ADD COLUMN IF NOT EXISTS snapshot_total_quantity INT;
ALTER TABLE device_movement_logs ADD COLUMN IF NOT EXISTS snapshot_available_quantity INT;
ALTER TABLE device_movement_logs ADD COLUMN IF NOT EXISTS snapshot_in_use_quantity INT;
ALTER TABLE device_movement_logs ADD COLUMN IF NOT EXISTS snapshot_repairing_quantity INT;

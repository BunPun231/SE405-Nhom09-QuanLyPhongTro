-- Allow NULL device_id in maintenance_details for repairs without device replacement
ALTER TABLE maintenance_details ALTER COLUMN device_id DROP NOT NULL;

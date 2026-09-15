-- Add billing settings to motels
ALTER TABLE motels
    ADD COLUMN IF NOT EXISTS billing_cycle_day INTEGER,
    ADD COLUMN IF NOT EXISTS deposit_percent NUMERIC(5,2);

-- Optional defaults can be set at application level

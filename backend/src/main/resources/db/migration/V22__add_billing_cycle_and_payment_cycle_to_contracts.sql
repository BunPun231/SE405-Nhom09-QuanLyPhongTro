-- Add billing_cycle_day and payment_cycle_months to contracts
ALTER TABLE contracts
    ADD COLUMN IF NOT EXISTS billing_cycle_day INTEGER,
    ADD COLUMN IF NOT EXISTS payment_cycle_months INTEGER;

-- Backfill existing contracts with reasonable defaults
UPDATE contracts SET billing_cycle_day = 30 WHERE billing_cycle_day IS NULL;
UPDATE contracts SET payment_cycle_months = 1 WHERE payment_cycle_months IS NULL;

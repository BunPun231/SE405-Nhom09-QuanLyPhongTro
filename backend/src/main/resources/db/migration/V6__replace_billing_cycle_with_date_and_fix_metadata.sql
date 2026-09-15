-- ======================================================================
-- Replace billing_cycle with billing_date & fix metadata type (UC66 refactor)
-- ======================================================================

DO $$
BEGIN
    -- 1. Drop billing_cycle constraint safely
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'contracts'::regclass
        AND conname = 'contracts_billing_cycle_check'
    ) THEN
        ALTER TABLE contracts DROP CONSTRAINT contracts_billing_cycle_check;
    END IF;
END $$;

-- 2. Drop billing_cycle column if present
ALTER TABLE contracts
DROP COLUMN IF EXISTS billing_cycle;

-- 3. Add billing_date column if missing
ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS billing_date DATE;

-- 4. Change contract_appendixes.metadata from JSONB to TEXT
ALTER TABLE contract_appendixes
ALTER COLUMN metadata TYPE TEXT USING metadata::text;
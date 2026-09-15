-- ======================================================================
-- Make V4 constraint idempotent (UC66)
-- ======================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'contracts'::regclass
        AND conname = 'contracts_billing_cycle_check'
    ) THEN
        ALTER TABLE contracts
        ADD CONSTRAINT contracts_billing_cycle_check
        CHECK (billing_cycle IN ('MONTHLY','QUARTERLY','YEARLY'));
    END IF;
END $$;
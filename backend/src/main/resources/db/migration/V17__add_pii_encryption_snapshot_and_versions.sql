-- Add encrypted PII columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS national_id VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(30);
ALTER TABLE users ADD COLUMN IF NOT EXISTS bank_account_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100);

ALTER TABLE resident_profiles ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(30);
ALTER TABLE resident_profiles ADD COLUMN IF NOT EXISTS bank_account_name VARCHAR(100);
ALTER TABLE resident_profiles ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100);

-- Add optimistic locking version columns
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;

-- Add invoice calculation snapshot
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS calculation_snapshot JSONB;

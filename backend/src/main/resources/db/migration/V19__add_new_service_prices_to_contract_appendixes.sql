-- Add new_service_prices JSONB column to contract_appendixes for bulk apply price changes
ALTER TABLE contract_appendixes
    ADD COLUMN IF NOT EXISTS new_service_prices JSONB;

CREATE INDEX IF NOT EXISTS idx_contract_appendixes_new_service_prices ON contract_appendixes USING gin (new_service_prices);

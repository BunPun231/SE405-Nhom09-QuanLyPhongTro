-- ======================================================================
-- Contract adjustments refactor (UC66)
-- ======================================================================

ALTER TABLE contracts
ADD COLUMN IF NOT EXISTS rent_price DECIMAL(12,2) NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS billing_cycle VARCHAR(20) NOT NULL DEFAULT 'MONTHLY';

ALTER TABLE contracts
ADD CONSTRAINT contracts_billing_cycle_check
CHECK (billing_cycle IN ('MONTHLY','QUARTERLY','YEARLY'));

ALTER TABLE contract_appendixes
ADD COLUMN IF NOT EXISTS new_rent_price DECIMAL(12,2),
ADD COLUMN IF NOT EXISTS appendix_type VARCHAR(30),
ADD COLUMN IF NOT EXISTS metadata JSONB;

UPDATE contract_appendixes
SET appendix_type = 'PRICE_CHANGE'
WHERE appendix_type IS NULL;

ALTER TABLE contract_appendixes
ALTER COLUMN appendix_type SET NOT NULL;

ALTER TABLE contract_appendixes
DROP COLUMN IF EXISTS new_base_price,
DROP COLUMN IF EXISTS new_service_prices,
DROP COLUMN IF EXISTS reason,
DROP COLUMN IF EXISTS pdf_url;

CREATE TABLE IF NOT EXISTS contract_service_items (
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    contract_id BIGINT NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    service_id  BIGINT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    quantity    INT NOT NULL DEFAULT 1,
    PRIMARY KEY (contract_id, service_id)
);

CREATE INDEX IF NOT EXISTS idx_contract_service_items_tenant_id
ON contract_service_items(tenant_id);

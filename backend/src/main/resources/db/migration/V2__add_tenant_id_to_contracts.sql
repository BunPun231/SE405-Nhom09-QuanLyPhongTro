-- ======================================================================
-- Add tenant_id column to contract-related tables for multi-tenancy
-- ======================================================================

-- Add tenant_id to contracts table
ALTER TABLE contracts
ADD COLUMN tenant_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

-- Add foreign key constraint
ALTER TABLE contracts
ADD CONSTRAINT fk_contracts_tenant_id
FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

-- Add index for tenant_id to improve query performance
CREATE INDEX idx_contracts_tenant_id ON contracts(tenant_id);

-- Add composite index for tenant_id + status (common query pattern)
CREATE INDEX idx_contracts_tenant_id_status ON contracts(tenant_id, status);

-- ======================================================================
-- Add tenant_id to contract_residents table
-- ======================================================================
ALTER TABLE contract_residents
ADD COLUMN tenant_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

-- Add foreign key constraint
ALTER TABLE contract_residents
ADD CONSTRAINT fk_contract_residents_tenant_id
FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

-- Add index for tenant_id
CREATE INDEX idx_contract_residents_tenant_id ON contract_residents(tenant_id);

-- ======================================================================
-- Add tenant_id to contract_appendixes table
-- ======================================================================
ALTER TABLE contract_appendixes
ADD COLUMN tenant_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

-- Add foreign key constraint
ALTER TABLE contract_appendixes
ADD CONSTRAINT fk_contract_appendixes_tenant_id
FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

-- Add index for tenant_id
CREATE INDEX idx_contract_appendixes_tenant_id ON contract_appendixes(tenant_id);

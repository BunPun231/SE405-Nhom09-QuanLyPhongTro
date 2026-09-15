-- Thêm tenant_id vào invoices
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS room_id BIGINT REFERENCES rooms(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS cancel_reason TEXT;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS balance_deduction DECIMAL(12,2) NOT NULL DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS invoice_type VARCHAR(20) DEFAULT 'MONTHLY'
    CHECK (invoice_type IN ('MONTHLY', 'SETTLEMENT'));

-- Thêm tenant_id vào meter_readings
ALTER TABLE meter_readings ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);
ALTER TABLE meter_readings ADD COLUMN IF NOT EXISTS room_id BIGINT REFERENCES rooms(id);

-- Thêm tenant_id vào transactions
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_room_id ON invoices(room_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_meter_readings_tenant_id ON meter_readings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_meter_readings_room_id ON meter_readings(room_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tenant_id ON transactions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_transactions_invoice_id ON transactions(invoice_id);

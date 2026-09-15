ALTER TABLE contracts ADD COLUMN credit_balance DECIMAL(12,2) DEFAULT 0 CHECK (credit_balance >= 0);

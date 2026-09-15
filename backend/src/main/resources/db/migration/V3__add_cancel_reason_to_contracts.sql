-- Add cancel_reason column for UC67
ALTER TABLE contracts
ADD COLUMN cancel_reason TEXT;
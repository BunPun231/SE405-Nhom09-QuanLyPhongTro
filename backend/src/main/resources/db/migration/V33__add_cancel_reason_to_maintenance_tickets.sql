-- Add optional cancellation reason to maintenance tickets
ALTER TABLE maintenance_tickets
    ADD COLUMN IF NOT EXISTS cancel_reason TEXT;

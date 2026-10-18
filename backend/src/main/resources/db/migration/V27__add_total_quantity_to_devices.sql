-- Migration V2: Add total_quantity to devices table for batch inventory management
ALTER TABLE devices ADD COLUMN IF NOT EXISTS total_quantity INT NOT NULL DEFAULT 1;

-- V24: Add has_completed_onboarding to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN NOT NULL DEFAULT FALSE;
COMMENT ON COLUMN users.has_completed_onboarding IS 'Trạng thái hoàn thành hướng dẫn nhập môn của Manager';

CREATE TABLE password_history (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_history_user_id ON password_history(user_id);

-- Add column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS session_version INT DEFAULT 0;

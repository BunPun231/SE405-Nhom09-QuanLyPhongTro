-- V23: Add bank_config to motels, tenant_id to notifications, create device_tokens and notification_outbox tables

-- 1. Add bank_config column to motels table
ALTER TABLE motels ADD COLUMN IF NOT EXISTS bank_config JSONB;
COMMENT ON COLUMN motels.bank_config IS 'Cấu hình VietQR/tài khoản ngân hàng của khu trọ';

-- 2. Add tenant_id column to notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_notifications_tenant_id ON notifications(tenant_id);

-- 3. Modify CHECK constraint on notifications.type
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN ('SYSTEM','REMINDER','MAINTENANCE','CONTRACT','BILLING','PAYMENT','GENERAL'));

-- 4. Create device_tokens table
CREATE TABLE IF NOT EXISTS device_tokens (
    id                BIGSERIAL PRIMARY KEY,
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token             VARCHAR(255) NOT NULL UNIQUE,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
COMMENT ON TABLE device_tokens IS 'Lưu FCM Token của người dùng phục vụ push notification';

-- 5. Create notification_outbox table
CREATE TABLE IF NOT EXISTS notification_outbox (
    id                BIGSERIAL PRIMARY KEY,
    tenant_id         UUID REFERENCES tenants(id) ON DELETE CASCADE,
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title             VARCHAR(255) NOT NULL,
    content           TEXT NOT NULL,
    type              VARCHAR(30) NOT NULL,
    action_url        TEXT,
    status            VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'SENT', 'FAILED')),
    retry_count       INT NOT NULL DEFAULT 0,
    error_message     TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_notification_outbox_status ON notification_outbox(status);
CREATE INDEX IF NOT EXISTS idx_notification_outbox_created_at ON notification_outbox(created_at);
COMMENT ON TABLE notification_outbox IS 'Transactional Outbox lưu các tin chờ đẩy qua Firebase FCM';

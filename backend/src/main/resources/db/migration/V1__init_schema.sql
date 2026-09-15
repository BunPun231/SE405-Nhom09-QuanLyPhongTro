-- ======================================================================
-- SMART ROOM MANAGEMENT SYSTEM – DATABASE SCHEMA (RESIDENT VERSION)
-- PostgreSQL 14+
-- Terminology:
--    tenants / tenant_id = SaaS workspace (chủ nhà)
--    residents           = người thuê phòng (thay cho room_tenant cũ)
-- ======================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------
-- 1. tenants (SaaS workspace)
-- ------------------------------------------------------------------
CREATE TABLE tenants (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(255) NOT NULL,
    owner_user_id   UUID NOT NULL,                    -- FK users(id)
    status          VARCHAR(20) NOT NULL DEFAULT 'TRIAL'
                    CHECK (status IN ('ACTIVE', 'SUSPENDED', 'TRIAL')),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP
);
COMMENT ON TABLE tenants IS 'Không gian làm việc của chủ nhà (SaaS tenant)';
COMMENT ON COLUMN tenants.owner_user_id IS 'User (role=MANAGER) sở hữu tenant này';

-- ------------------------------------------------------------------
-- 2. subscription_plans
-- ------------------------------------------------------------------
CREATE TABLE subscription_plans (
    id                BIGSERIAL PRIMARY KEY,
    name              VARCHAR(100) NOT NULL UNIQUE,
    price_per_month   DECIMAL(12,2) NOT NULL,
    max_motels        INT NOT NULL,
    max_rooms         INT NOT NULL,
    max_technicians   INT NOT NULL DEFAULT 0,
    storage_quota_mb  INT NOT NULL,
    allowed_modules   JSONB,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE subscription_plans IS 'Các gói dịch vụ SaaS (Cơ bản, Nâng cao, Dùng thử)';

-- ------------------------------------------------------------------
-- 3. tenant_subscriptions
-- ------------------------------------------------------------------
CREATE TABLE tenant_subscriptions (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan_id     BIGINT NOT NULL REFERENCES subscription_plans(id),
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    status      VARCHAR(20) NOT NULL
                CHECK (status IN ('ACTIVE','EXPIRED','CANCELLED','PENDING_PAYMENT')),
    auto_renew  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 4. tenant_quotas
-- ------------------------------------------------------------------
CREATE TABLE tenant_quotas (
    tenant_id               UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    current_motels          INT NOT NULL DEFAULT 0,
    current_rooms           INT NOT NULL DEFAULT 0,
    current_storage_used_mb INT NOT NULL DEFAULT 0,
    last_updated            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 5. users (tài khoản chung)
-- ------------------------------------------------------------------
CREATE TABLE users (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id             UUID REFERENCES tenants(id) ON DELETE CASCADE,
    phone                 VARCHAR(15) NOT NULL UNIQUE,
    email                 VARCHAR(255),
    password_hash         VARCHAR(255) NOT NULL,
    full_name             VARCHAR(255) NOT NULL,
    role                  VARCHAR(20) NOT NULL
                          CHECK (role IN ('ADMIN','MANAGER','TECHNICIAN','RESIDENT')),
    status                VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                          CHECK (status IN ('ACTIVE','LOCKED','PENDING','INACTIVE')),
    must_change_password  BOOLEAN NOT NULL DEFAULT FALSE,
    avatar_url            TEXT,
    created_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP,
    last_login_at         TIMESTAMP,
    lock_reason           TEXT
);
COMMENT ON TABLE users IS 'Tài khoản đăng nhập cho mọi actor';
COMMENT ON COLUMN users.tenant_id IS 'NULL với Admin, ngược lại là SaaS tenant sở hữu user';

-- ------------------------------------------------------------------
-- 6. resident_profiles (thay cho tenant_profiles)
-- ------------------------------------------------------------------
CREATE TABLE resident_profiles (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    id_card_number      VARCHAR(20) NOT NULL UNIQUE,
    id_card_front_url   TEXT,
    id_card_back_url    TEXT,
    verified_at         TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP
);
COMMENT ON TABLE resident_profiles IS 'Hồ sơ định danh mở rộng cho người thuê phòng (role=RESIDENT)';

-- ------------------------------------------------------------------
-- 7. technician_profiles
-- ------------------------------------------------------------------
CREATE TABLE technician_profiles (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    expertise           TEXT,
    is_available        BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_motel_ids  TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP
);

-- ------------------------------------------------------------------
-- 8. profile_change_requests (yêu cầu sửa hồ sơ của resident)
-- ------------------------------------------------------------------
CREATE TABLE profile_change_requests (
    id               BIGSERIAL PRIMARY KEY,
    resident_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    new_full_name    VARCHAR(255),
    new_id_card      VARCHAR(20),
    proof_image_url  TEXT NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    reviewed_by      UUID REFERENCES users(id),
    rejection_reason TEXT,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP
);

-- ------------------------------------------------------------------
-- 9. motels
-- ------------------------------------------------------------------
CREATE TABLE motels (
    id           BIGSERIAL PRIMARY KEY,
    tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name         VARCHAR(255) NOT NULL,
    address      TEXT NOT NULL,
    total_floors INT NOT NULL,
    description  TEXT,
    is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP,
    CONSTRAINT motels_tenant_name_unique UNIQUE (tenant_id, name)
);
COMMENT ON TABLE motels IS 'Khu trọ / Tòa nhà cho thuê';

-- ------------------------------------------------------------------
-- 10. rooms
-- ------------------------------------------------------------------
CREATE TABLE rooms (
    id                     BIGSERIAL PRIMARY KEY,
    motel_id               BIGINT NOT NULL REFERENCES motels(id) ON DELETE CASCADE,
    room_number            VARCHAR(20) NOT NULL,
    floor                  INT NOT NULL,
    area                   DECIMAL(10,2),
    base_price             DECIMAL(12,2) NOT NULL,
    status                 VARCHAR(20) NOT NULL DEFAULT 'EMPTY'
                           CHECK (status IN ('EMPTY','DEPOSITED','RENTED','REPAIRING','OUT_OF_BUSINESS')),
    current_residents_count INT NOT NULL DEFAULT 0,
    is_deleted             BOOLEAN NOT NULL DEFAULT FALSE,
    description            TEXT,
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP,
    CONSTRAINT rooms_motel_room_unique UNIQUE (motel_id, room_number)
);

-- ------------------------------------------------------------------
-- 11. services
-- ------------------------------------------------------------------
CREATE TABLE services (
    id           BIGSERIAL PRIMARY KEY,
    motel_id     BIGINT NOT NULL REFERENCES motels(id) ON DELETE CASCADE,
    name         VARCHAR(100) NOT NULL,
    charge_type  VARCHAR(20) NOT NULL
                 CHECK (charge_type IN ('FIXED','PER_PERSON','PER_INDEX','PER_QUANTITY')),
    unit         VARCHAR(20),
    is_mandatory BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP,
    CONSTRAINT services_motel_name_unique UNIQUE (motel_id, name)
);

-- ------------------------------------------------------------------
-- 12. service_pricing
-- ------------------------------------------------------------------
CREATE TABLE service_pricing (
    id             BIGSERIAL PRIMARY KEY,
    service_id     BIGINT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    effective_from DATE NOT NULL,
    effective_to   DATE,
    base_price     DECIMAL(12,2),
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 13. service_tier_pricing
-- ------------------------------------------------------------------
CREATE TABLE service_tier_pricing (
    id             BIGSERIAL PRIMARY KEY,
    pricing_id     BIGINT NOT NULL REFERENCES service_pricing(id) ON DELETE CASCADE,
    tier_start     DECIMAL(12,2) NOT NULL,
    tier_end       DECIMAL(12,2),
    price_per_unit DECIMAL(12,2) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_tier_range CHECK (tier_end IS NULL OR tier_start <= tier_end)
);

-- ------------------------------------------------------------------
-- 14. service_usages
-- ------------------------------------------------------------------
CREATE TABLE service_usages (
    id                  BIGSERIAL PRIMARY KEY,
    room_id             BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    service_id          BIGINT NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    registered_quantity INT NOT NULL DEFAULT 1,
    start_index         DECIMAL(12,2),
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE','PENDING_CANCELLATION')),
    registered_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP
);

-- ------------------------------------------------------------------
-- 15. devices
-- ------------------------------------------------------------------
CREATE TABLE devices (
    id             BIGSERIAL PRIMARY KEY,
    motel_id       BIGINT NOT NULL REFERENCES motels(id) ON DELETE CASCADE,
    name           VARCHAR(255) NOT NULL,
    brand          VARCHAR(100),
    purchase_price DECIMAL(12,2),
    purchase_date  DATE,
    status         VARCHAR(20) NOT NULL DEFAULT 'IN_STOCK'
                   CHECK (status IN ('IN_STOCK','IN_USE','BROKEN','REPAIRING')),
    is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP
);

-- ------------------------------------------------------------------
-- 16. device_usages
-- ------------------------------------------------------------------
CREATE TABLE device_usages (
    id                 BIGSERIAL PRIMARY KEY,
    device_id          BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    room_id            BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    assigned_quantity  INT NOT NULL DEFAULT 1,
    condition          VARCHAR(20) NOT NULL CHECK (condition IN ('NEW','GOOD','BROKEN')),
    assigned_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP
);

-- ------------------------------------------------------------------
-- 17. device_movement_logs
-- ------------------------------------------------------------------
CREATE TABLE device_movement_logs (
    id           BIGSERIAL PRIMARY KEY,
    device_id    BIGINT NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    from_room_id BIGINT REFERENCES rooms(id),
    to_room_id   BIGINT REFERENCES rooms(id),
    action       VARCHAR(20) NOT NULL CHECK (action IN ('ASSIGN','RECALL')),
    changed_by   UUID NOT NULL REFERENCES users(id),
    timestamp    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note         TEXT
);

-- ------------------------------------------------------------------
-- 18. contracts
-- ------------------------------------------------------------------
CREATE TABLE contracts (
    id                      BIGSERIAL PRIMARY KEY,
    room_id                 BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    primary_resident_user_id UUID NOT NULL REFERENCES users(id),
    start_date              DATE NOT NULL,
    end_date                DATE NOT NULL,
    deposit_amount          DECIMAL(12,2) NOT NULL DEFAULT 0,
    deposit_status          VARCHAR(20) NOT NULL DEFAULT 'UNPAID'
                            CHECK (deposit_status IN ('UNPAID','PAID','REFUNDED','DEDUCTED')),
    status                  VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
                            CHECK (status IN ('DRAFT','ACTIVE','LIQUIDATED','CANCELED','PENDING_LIQUIDATION')),
    intended_move_out_date  DATE,
    pdf_url                 TEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP,
    created_by              UUID NOT NULL REFERENCES users(id)
);

-- ------------------------------------------------------------------
-- 19. contract_residents (thay cho contract_tenants)
-- ------------------------------------------------------------------
CREATE TABLE contract_residents (
    contract_id     BIGINT NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    resident_user_id UUID NOT NULL REFERENCES users(id),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    joined_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at         TIMESTAMP,
    PRIMARY KEY (contract_id, resident_user_id)
);

-- ------------------------------------------------------------------
-- 20. contract_appendixes
-- ------------------------------------------------------------------
CREATE TABLE contract_appendixes (
    id                BIGSERIAL PRIMARY KEY,
    contract_id       BIGINT NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    effective_date    DATE NOT NULL,
    new_base_price    DECIMAL(12,2),
    new_service_prices JSONB,
    reason            TEXT NOT NULL,
    pdf_url           TEXT,
    created_by        UUID NOT NULL REFERENCES users(id),
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 21. meter_readings
-- ------------------------------------------------------------------
CREATE TABLE meter_readings (
    id                 BIGSERIAL PRIMARY KEY,
    service_usage_id   BIGINT NOT NULL REFERENCES service_usages(id) ON DELETE CASCADE,
    billing_month      DATE NOT NULL,
    old_reading        DECIMAL(12,2) NOT NULL,
    new_reading        DECIMAL(12,2) NOT NULL,
    consumption        DECIMAL(12,2) GENERATED ALWAYS AS (new_reading - old_reading) STORED,
    reading_image_url  TEXT,
    status             VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                       CHECK (status IN ('PENDING','APPROVED','REJECTED')),
    submitted_by       UUID NOT NULL REFERENCES users(id),
    approved_by        UUID REFERENCES users(id),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP,
    CONSTRAINT check_new_ge_old CHECK (new_reading >= old_reading)
);

-- ------------------------------------------------------------------
-- 22. invoices
-- ------------------------------------------------------------------
CREATE TABLE invoices (
    id            BIGSERIAL PRIMARY KEY,
    contract_id   BIGINT NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    billing_month DATE NOT NULL,
    total_amount  DECIMAL(12,2) NOT NULL,
    paid_amount   DECIMAL(12,2) NOT NULL DEFAULT 0,
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                  CHECK (status IN ('PENDING','PARTIAL','PAID','VOID')),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    due_date      DATE NOT NULL
);

-- ------------------------------------------------------------------
-- 23. invoice_details
-- ------------------------------------------------------------------
CREATE TABLE invoice_details (
    id          BIGSERIAL PRIMARY KEY,
    invoice_id  BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description VARCHAR(255) NOT NULL,
    quantity    DECIMAL(12,2) NOT NULL,
    unit_price  DECIMAL(12,2) NOT NULL,
    line_total  DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    service_id  BIGINT REFERENCES services(id)
);

-- ------------------------------------------------------------------
-- 24. transactions
-- ------------------------------------------------------------------
CREATE TABLE transactions (
    id                BIGSERIAL PRIMARY KEY,
    invoice_id        BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    amount            DECIMAL(12,2) NOT NULL,
    transaction_ref   VARCHAR(100) UNIQUE,
    payment_method    VARCHAR(20) NOT NULL CHECK (payment_method IN ('VIETQR','CASH','BANK_TRANSFER')),
    bank_code         VARCHAR(20),
    status            VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS','FAILED','PENDING_RECONCILE')),
    paid_at           TIMESTAMP,
    raw_webhook_data  JSONB,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 25. resident_balances (thay cho tenant_balances)
-- ------------------------------------------------------------------
CREATE TABLE resident_balances (
    resident_user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    balance          DECIMAL(12,2) NOT NULL DEFAULT 0,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE resident_balances IS 'Số dư tài khoản của người thuê phòng (tiền thừa các kỳ trước)';

-- ------------------------------------------------------------------
-- 26. maintenance_tickets
-- ------------------------------------------------------------------
CREATE TABLE maintenance_tickets (
    id            BIGSERIAL PRIMARY KEY,
    room_id       BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    reported_by   UUID NOT NULL REFERENCES users(id),
    assigned_to   UUID REFERENCES users(id),
    category      VARCHAR(50) NOT NULL,
    description   TEXT NOT NULL,
    before_images TEXT[],
    status        VARCHAR(20) NOT NULL DEFAULT 'OPEN'
                  CHECK (status IN ('OPEN','PROCESSING','COMPLETED','ESCALATED','CANCELLED')),
    priority      VARCHAR(10) NOT NULL DEFAULT 'MEDIUM'
                  CHECK (priority IN ('LOW','MEDIUM','HIGH','URGENT')),
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP,
    completed_at  TIMESTAMP
);

-- ------------------------------------------------------------------
-- 27. maintenance_details
-- ------------------------------------------------------------------
CREATE TABLE maintenance_details (
    id                  BIGSERIAL PRIMARY KEY,
    ticket_id           BIGINT NOT NULL REFERENCES maintenance_tickets(id) ON DELETE CASCADE,
    device_id           BIGINT NOT NULL REFERENCES devices(id),
    quantity_used       INT NOT NULL,
    unit_price_snapshot DECIMAL(12,2) NOT NULL,
    after_images        TEXT[],
    note                TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 28. notifications
-- ------------------------------------------------------------------
CREATE TABLE notifications (
    id                BIGSERIAL PRIMARY KEY,
    recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title             VARCHAR(255) NOT NULL,
    content           TEXT NOT NULL,
    type              VARCHAR(30) NOT NULL
                      CHECK (type IN ('SYSTEM','REMINDER','MAINTENANCE','CONTRACT','BILLING')),
    is_read           BOOLEAN NOT NULL DEFAULT FALSE,
    action_url        TEXT,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    read_at           TIMESTAMP
);

-- ------------------------------------------------------------------
-- 29. audit_logs
-- ------------------------------------------------------------------
CREATE TABLE audit_logs (
    id          BIGSERIAL PRIMARY KEY,
    actor_id    UUID REFERENCES users(id),
    action      VARCHAR(50) NOT NULL,
    target_type VARCHAR(50),
    target_id   VARCHAR(255),
    old_value   JSONB,
    new_value   JSONB,
    ip_address  INET,
    user_agent  TEXT,
    timestamp   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 30. activity_logs
-- ------------------------------------------------------------------
CREATE TABLE activity_logs (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    actor_id    UUID NOT NULL REFERENCES users(id),
    action      VARCHAR(50) NOT NULL,
    target_type VARCHAR(50),
    target_id   VARCHAR(255),
    summary     TEXT NOT NULL,
    timestamp   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------
-- 31. system_configs
-- ------------------------------------------------------------------
CREATE TABLE system_configs (
    key           VARCHAR(100) PRIMARY KEY,
    value         TEXT NOT NULL,
    is_encrypted  BOOLEAN NOT NULL DEFAULT FALSE,
    description   TEXT,
    updated_at    TIMESTAMP,
    updated_by    UUID REFERENCES users(id)
);

-- ------------------------------------------------------------------
-- 32. workspace_configs
-- ------------------------------------------------------------------
CREATE TABLE workspace_configs (
    tenant_id   UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    config      JSONB NOT NULL,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by  UUID REFERENCES users(id)
);

-- ======================================================================
-- INDEXES
-- ======================================================================

-- users
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_phone ON users(phone);

-- rooms
CREATE INDEX idx_rooms_motel_id ON rooms(motel_id);
CREATE INDEX idx_rooms_status ON rooms(status);

-- contracts
CREATE INDEX idx_contracts_room_id ON contracts(room_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_primary_resident ON contracts(primary_resident_user_id);

-- invoices
CREATE INDEX idx_invoices_contract_id ON invoices(contract_id);
CREATE INDEX idx_invoices_billing_month ON invoices(billing_month);

-- meter_readings
CREATE INDEX idx_meter_readings_service_usage_id ON meter_readings(service_usage_id);
CREATE INDEX idx_meter_readings_billing_month ON meter_readings(billing_month);

-- maintenance_tickets
CREATE INDEX idx_tickets_assigned_to ON maintenance_tickets(assigned_to);
CREATE INDEX idx_tickets_status ON maintenance_tickets(status);

-- notifications
CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Resident related indexes
CREATE INDEX idx_resident_profiles_id_card ON resident_profiles(id_card_number);
CREATE INDEX idx_resident_balances_user ON resident_balances(resident_user_id);
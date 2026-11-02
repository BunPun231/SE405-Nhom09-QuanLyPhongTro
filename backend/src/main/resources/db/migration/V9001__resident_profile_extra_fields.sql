-- V9001 (Module VI - Khách thuê, UC49/UC53):
-- Bổ sung ngày sinh, giới tính, ghi chú cho hồ sơ khách thuê.
-- Đánh index họ tên/SĐT để tìm kiếm nhanh (BR50.8).
ALTER TABLE resident_profiles ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE resident_profiles ADD COLUMN IF NOT EXISTS gender VARCHAR(10);
ALTER TABLE resident_profiles ADD COLUMN IF NOT EXISTS notes TEXT;

CREATE INDEX IF NOT EXISTS idx_users_tenant_role_full_name ON users(tenant_id, role, LOWER(full_name));
CREATE INDEX IF NOT EXISTS idx_contract_residents_resident ON contract_residents(resident_user_id);

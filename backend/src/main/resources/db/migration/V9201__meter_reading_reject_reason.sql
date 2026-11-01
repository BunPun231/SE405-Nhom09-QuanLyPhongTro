-- UC70 (US70.2): lưu lý do Quản lý từ chối chỉ số để Khách thuê biết cần sửa gì.
ALTER TABLE meter_readings ADD COLUMN IF NOT EXISTS reject_reason TEXT;

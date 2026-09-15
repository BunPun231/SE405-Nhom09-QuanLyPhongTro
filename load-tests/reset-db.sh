#!/usr/bin/env bash
# ─── reset-db.sh ──────────────────────────────────────────────────────────────
# Reset hoàn toàn database bằng cách Drop Schema và để Flyway tự tạo lại.
# Đây là cách sạch sẽ và ổn định nhất, tránh mọi lỗi Flyway Checksum.
# ──────────────────────────────────────────────────────────────────────────────

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✅ $*${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $*${NC}"; }
err()  { echo -e "${RED}  ❌ $*${NC}"; exit 1; }

DB_CONTAINER="${DB_CONTAINER:-rental-dev-postgres}"
DB_USER="${DB_USER:-rental_dev}"
DB_NAME="${DB_NAME:-rental_management}"

echo ""
echo "🗑️  ===== RESET DATABASE (Drop Schema) ====="
echo ""
warn "Sẽ DROP SCHEMA public CASCADE và để backend tự tạo lại khi khởi động."
echo ""

# Kiểm tra container
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  err "Container '$DB_CONTAINER' chưa chạy."
fi

ok "Kết nối tới $DB_CONTAINER..."

# Drop schema and recreate
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO public;
"

ok "Đã dọn dẹp Database thành công."
echo "Khi Spring Boot khởi động, Flyway sẽ tự động chạy lại toàn bộ migrations (V1 -> V16)."
echo ""

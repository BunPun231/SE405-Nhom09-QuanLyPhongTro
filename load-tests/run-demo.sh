#!/usr/bin/env bash
# ─── run-demo.sh ──────────────────────────────────────────────────────────────
# Kịch bản chạy toàn bộ Demo Performance từ A-Z một cách tự động và ổn định.
# 
# Các bước:
# 1. Reset Database (SQL truncate, an toàn cho Flyway)
# 2. Khởi động Spring Boot Backend (chạy ngầm)
# 3. Khởi động Monitoring Stack (Prometheus trên host, Grafana Docker)
# 4. Seed dữ liệu lớn (100 phòng, 100 khách, hóa đơn...)
# 5. Chạy K6 Spike Test đánh giá caching
# ──────────────────────────────────────────────────────────────────────────────

set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✅ $*${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $*${NC}"; }
err()  { echo -e "${RED}  ❌ $*${NC}"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🚀 ===== BẮT ĐẦU KỊCH BẢN DEMO PERFORMANCE ====="

# 1. Reset Database
echo ""
echo "▶ BƯỚC 1: Reset Database"
bash load-tests/reset-db.sh

# 2. Khởi động Backend
echo ""
echo "▶ BƯỚC 2: Khởi động Backend"
# Kill backend cũ nếu có
if ss -tlnp | grep -q ':8080'; then
  warn "Port 8080 đang bận, đang kill tiến trình cũ..."
  fuser -k 8080/tcp 2>/dev/null || true
  sleep 3
fi

echo "  Đang khởi động Spring Boot (log: /tmp/backend.log)..."
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev > /tmp/backend.log 2>&1 &
BACKEND_PID=$!
cd ..

echo -n "  Đang đợi Backend healthy "
BACKEND_UP=false
for i in {1..60}; do
  if curl -s http://localhost:8080/actuator/health | grep -q UP; then
    BACKEND_UP=true
    break
  fi
  echo -n "."
  sleep 2
done
echo ""

if [ "$BACKEND_UP" = true ]; then
  ok "Backend đã sẵn sàng! (PID $BACKEND_PID)"
else
  err "Backend không khởi động được sau 120s. Xem log: cat /tmp/backend.log"
fi

# 3. Khởi động Monitoring
echo ""
echo "▶ BƯỚC 3: Khởi động Monitoring Stack"
bash load-tests/start-monitoring.sh

# 4. Seed Data
echo ""
echo "▶ BƯỚC 4: Chạy Massive Seed Data"
node load-tests/seed-massive.js

# 5. Chạy K6
echo ""
echo "▶ BƯỚC 5: Chạy K6 Spike Test"
echo "  Mở Grafana: http://localhost:3100 (admin/admin)"
echo "  Xem dashboard JVM (Micrometer) để thấy HTTP requests và Cache Metrics"
echo "  Bắt đầu bắn request trong 5 giây..."
sleep 5
k6 run load-tests/dashboard_spike_test.js

echo ""
echo "🎉 ===== DEMO HOÀN TẤT ====="
echo "Backend vẫn đang chạy ngầm ở PID $BACKEND_PID."
echo "Để tắt backend, chạy: kill $BACKEND_PID"

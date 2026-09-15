#!/usr/bin/env bash
# ─── start-monitoring.sh ───────────────────────────────────────────────────────
# Khởi động toàn bộ monitoring stack cho Demo Performance:
#   - Prometheus (chạy trực tiếp trên host, tránh Docker Desktop VM barrier)
#   - Grafana     (chạy Docker, port 3100)
#
# Môi trường: Docker Desktop for Linux
# Lý do chạy Prometheus trên host: Docker Desktop tạo VM layer khiến container
# không thể reach localhost:8080 của host qua bất kỳ bridge IP nào.
#
# Sử dụng:
#   chmod +x load-tests/start-monitoring.sh
#   ./load-tests/start-monitoring.sh
# ──────────────────────────────────────────────────────────────────────────────

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROM_BIN="$PROJECT_ROOT/docker/prometheus-binary/prometheus"
PROM_DATA="$PROJECT_ROOT/docker/prometheus/data"
PROM_CONFIG="$PROJECT_ROOT/docker/prometheus/prometheus.yml"
PROM_PID_FILE="/tmp/srr_prometheus.pid"

# ─── Màu sắc ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✅ $*${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $*${NC}"; }
err()  { echo -e "${RED}  ❌ $*${NC}"; exit 1; }

echo ""
echo "🚀 ===== KHỞI ĐỘNG MONITORING STACK ====="
echo ""

# ─── 1. Kiểm tra prerequisite ─────────────────────────────────────────────────
[ -f "$PROM_BIN" ] || err "Prometheus binary không tồn tại: $PROM_BIN"
[ -f "$PROM_CONFIG" ] || err "Prometheus config không tồn tại: $PROM_CONFIG"

# Kiểm tra Spring Boot đang chạy
if ! curl -sf http://localhost:8080/actuator/health > /dev/null 2>&1; then
  warn "Spring Boot chưa chạy trên port 8080!"
  warn "Hãy chạy backend trước: cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev"
  warn "Tiếp tục khởi động Prometheus, nhưng target sẽ DOWN cho đến khi backend sẵn sàng"
fi

# ─── 2. Dừng Prometheus cũ nếu có ────────────────────────────────────────────
if [ -f "$PROM_PID_FILE" ]; then
  OLD_PID=$(cat "$PROM_PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    warn "Dừng Prometheus cũ (PID $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    sleep 2
  fi
  rm -f "$PROM_PID_FILE"
fi

# Cũng kill bất kỳ prometheus nào đang chạy trên port 9090
if ss -tlnp | grep -q ':9090'; then
  warn "Port 9090 đang bị chiếm, kill..."
  fuser -k 9090/tcp 2>/dev/null || true
  sleep 1
fi

# ─── 3. Khởi động Prometheus trên host ────────────────────────────────────────
mkdir -p "$PROM_DATA"
echo "📊 Khởi động Prometheus (host mode)..."
nohup "$PROM_BIN" \
  --config.file="$PROM_CONFIG" \
  --storage.tsdb.path="$PROM_DATA" \
  --web.listen-address="0.0.0.0:9090" \
  --storage.tsdb.retention.time=15d \
  > /tmp/srr_prometheus.log 2>&1 &

PROM_PID=$!
echo "$PROM_PID" > "$PROM_PID_FILE"

# Đợi Prometheus healthy
for i in $(seq 1 10); do
  sleep 1
  if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then
    ok "Prometheus đang chạy (PID $PROM_PID, port 9090)"
    break
  fi
  if [ $i -eq 10 ]; then
    err "Prometheus không khởi động được. Xem log: /tmp/srr_prometheus.log"
  fi
done

# ─── 4. Khởi động Grafana (Native Host) ───────────────────────────────────────
echo ""
echo "📈 Khởi động Grafana (Host mode, port 3100)..."

GRAFANA_DIR="$PROJECT_ROOT/docker/grafana-binary/grafana-v10.4.2"
GRAFANA_PID_FILE="/tmp/srr_grafana.pid"

if [ -f "$GRAFANA_PID_FILE" ]; then
  OLD_PID=$(cat "$GRAFANA_PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    warn "Dừng Grafana cũ (PID $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    sleep 2
  fi
  rm -f "$GRAFANA_PID_FILE"
fi

# Kill port 3100 nếu đang bận
if ss -tlnp | grep -q ':3100'; then
  fuser -k 3100/tcp 2>/dev/null || true
  sleep 1
fi

export GF_SERVER_HTTP_PORT=3100
export GF_SERVER_HTTP_ADDR=0.0.0.0
export GF_SECURITY_ADMIN_USER=admin
export GF_SECURITY_ADMIN_PASSWORD=admin
export GF_USERS_ALLOW_SIGN_UP=false
export GF_PATHS_PROVISIONING="$PROJECT_ROOT/docker/grafana/provisioning"

# Đảm bảo path provisioning đúng cho Native (path trong yaml trỏ tới /etc/grafana/ -> cần trỏ lại folder local)
sed -i "s|path: /etc/grafana/provisioning/dashboards|path: $PROJECT_ROOT/docker/grafana/provisioning/dashboards|g" "$PROJECT_ROOT/docker/grafana/provisioning/dashboards/dashboards.yml"

cd "$GRAFANA_DIR"
nohup ./bin/grafana server \
  --homepath "$GRAFANA_DIR" \
  > /tmp/srr_grafana.log 2>&1 &
cd "$PROJECT_ROOT"

GRAFANA_PID=$!
echo "$GRAFANA_PID" > "$GRAFANA_PID_FILE"

sleep 3
if curl -sf http://localhost:3100/api/health > /dev/null 2>&1; then
  ok "Grafana đang chạy (PID $GRAFANA_PID, port 3100)"
else
  warn "Grafana chưa sẵn sàng, đợi thêm..."
  sleep 5
fi

# ─── 5. Verify kết nối Prometheus → Spring Boot ───────────────────────────────
echo ""
echo "🔍 Kiểm tra Prometheus targets..."
sleep 5  # Đợi scrape đầu tiên
TARGETS=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null)
if echo "$TARGETS" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ok=0; down=0
for t in d['data']['activeTargets']:
    state=t['health']
    job=t['labels']['job']
    if state=='up': ok+=1; print(f'  ✅ {job}: UP')
    else: down+=1; print(f'  ❌ {job}: DOWN → {t.get(\"lastError\",\"\")[:80]}')
" 2>/dev/null; then
  true
else
  warn "Không đọc được targets từ Prometheus API"
fi

# Dừng docker compose grafana cũ (nếu có)
docker compose -f "$PROJECT_ROOT/docker-compose.monitor.yml" down grafana 2>/dev/null || true

# ─── SUMMARY ──────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         📡 MONITORING STACK SẴN SÀNG                   ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Prometheus  → http://localhost:9090                    ║"
echo "║  Grafana     → http://localhost:3100  (admin/admin)     ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Dashboard JVM đã được import tự động sẵn sàng!         ║"
echo "║  Dừng toàn bộ:                                          ║"
echo "║    kill \$(cat /tmp/srr_prometheus.pid)                   ║"
echo "║    kill \$(cat /tmp/srr_grafana.pid)                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

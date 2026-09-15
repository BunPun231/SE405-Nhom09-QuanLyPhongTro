/**
 * K6 Spike Test — "Bão truy cập Dashboard"
 * ==========================================
 * Kịch bản này mô phỏng tình huống bùng nổ truy cập vào API Dashboard Summary.
 * Mục tiêu: Chứng minh hiệu quả của Redis Cache trong việc giảm tải DB.
 *
 * Chạy:
 *   k6 run load-tests/dashboard_spike_test.js
 *
 * Xem kết quả realtime trên Grafana:
 *   http://localhost:3100  (import template ID 4701)
 *
 * Cần cài k6:
 *   sudo apt install k6          (Ubuntu/Debian)
 *   brew install k6              (macOS)
 *   winget install k6             (Windows)
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ─── Custom Metrics ────────────────────────────────────────────────────────────
const errorRate        = new Rate('error_rate');
const dashboardLatency = new Trend('dashboard_latency_ms', true);

// ─── Spike Test Options ────────────────────────────────────────────────────────
export const options = {
  // Spike: ramp-up nhanh → hold → ramp-down
  stages: [
    { duration: '10s', target: 50 },  // Stage 1: Ramp-up 0→50 VUs trong 10 giây
    { duration: '40s', target: 50 },  // Stage 2: Hold 50 VUs 40 giây (mở Grafana bây giờ!)
    { duration: '10s', target: 0  },  // Stage 3: Ramp-down về 0 trong 10 giây
  ],

  // Ngưỡng chất lượng (thresholds)
  thresholds: {
    // 95% request phải hoàn thành dưới 500ms
    'http_req_duration': ['p(95)<500'],
    // Tỉ lệ lỗi phải dưới 5%
    'error_rate': ['rate<0.05'],
    // Custom metric: 95% dashboard requests dưới 500ms
    'dashboard_latency_ms': ['p(95)<500'],
  },
};

// ─── Thông tin đăng nhập (đồng bộ với seed-massive.js) ───────────────────────
const BASE_URL      = 'http://localhost:8080';
const MANAGER_PHONE = '0911222333';
const MANAGER_PASS  = 'Demo@123456';

// ─── setup(): Đăng nhập 1 lần, chia sẻ token cho tất cả VUs ─────────────────
export function setup() {
  console.log('🔐 [setup] Đăng nhập lấy JWT token...');

  const loginPayload = JSON.stringify({
    identity: MANAGER_PHONE,
    password: MANAGER_PASS,
  });

  const loginRes = http.post(
    `${BASE_URL}/api/public/auth/login`,
    loginPayload,
    { headers: { 'Content-Type': 'application/json' } }
  );

  const loginOk = check(loginRes, {
    'login: status 200':  (r) => r.status === 200,
    'login: có accessToken': (r) => {
      try {
        return !!JSON.parse(r.body).data.accessToken;
      } catch {
        return false;
      }
    },
  });

  if (!loginOk) {
    console.error('❌ Đăng nhập thất bại! Kiểm tra backend đang chạy và seed data.');
    console.error('Response:', loginRes.body);
    // Trả về token rỗng — VUs sẽ fail nhưng test vẫn chạy để log lỗi
    return { accessToken: '' };
  }

  const accessToken = JSON.parse(loginRes.body).data.accessToken;
  console.log('✅ [setup] Đăng nhập thành công. Token đã sẵn sàng.');
  return { accessToken };
}

// ─── default function(): Chạy cho mỗi VU ────────────────────────────────────
export default function (data) {
  const { accessToken } = data;

  // Header Authorization Bearer
  const headers = {
    'Content-Type':  'application/json',
    'Authorization': `Bearer ${accessToken}`,
  };

  // ── HTTP GET: Dashboard Summary ──────────────────────────────────────────
  const startTime = Date.now();
  const dashRes = http.get(
    `${BASE_URL}/api/v1/reports/dashboard-summary`,
    { headers, tags: { name: 'DashboardSummary' } }
  );
  const latency = Date.now() - startTime;
  dashboardLatency.add(latency);

  // ── Kiểm tra kết quả ─────────────────────────────────────────────────────
  const success = check(dashRes, {
    'dashboard: status 200':     (r) => r.status === 200,
    'dashboard: có data':        (r) => {
      try {
        return JSON.parse(r.body).data !== undefined;
      } catch {
        return false;
      }
    },
    'dashboard: latency < 500ms': () => latency < 500,
  });

  errorRate.add(!success);

  // Log nhanh để theo dõi trong console
  if (!success) {
    console.warn(`⚠ VU ${__VU} iter ${__ITER}: status=${dashRes.status} latency=${latency}ms`);
  }

  // ── Sleep 1s: mô phỏng user đọc dashboard trước khi refresh ─────────────
  sleep(1);
}

// ─── teardown(): Tóm tắt sau test ────────────────────────────────────────────
export function teardown(data) {
  console.log('📊 [teardown] Spike Test hoàn tất!');
  console.log('   → Xem chi tiết metrics trên Grafana: http://localhost:3100');
  console.log('   → Prometheus: http://localhost:9090');
}

# 🚀 Performance Demo — Kiến trúc Observability & Redis Caching

> **Môn học:** Kiến trúc Phần mềm  
> **Demo chủ đề:** Observability Stack (Prometheus + Grafana) + Caching Tactic (Redis) + Load Test (K6 Spike Test)

---

## 🗺️ Kiến trúc Tổng quan

```text
┌──────────────────────────────────────────────────────────┐
│                     Load Test (K6)                       │
│              50 VUs → /api/v1/reports/dashboard-summary  │
└─────────────────────────┬────────────────────────────────┘
                          │ HTTP
                          ▼
┌─────────────────────────────────────────────────────────┐
│               Spring Boot (port 8080)                    │
│  ┌────────────────┐    ┌──────────────────────────────┐ │
│  │  ReportService │───▶│ Redis Cache (dashboardSummary)│ │
│  │  @Cacheable    │    │ key = tenantId               │ │
│  └───────┬────────┘    └──────────────────────────────┘ │
│          │ Cache MISS only                               │
│          ▼                                               │
│  ┌────────────────┐                                      │
│  │  PostgreSQL DB │   (HikariCP pool)                   │
│  └────────────────┘                                      │
│                                                          │
│  /actuator/prometheus  ◀── Prometheus scrapes every 10s │
└─────────────────────────────────────────────────────────┘
                          │ scrape
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Prometheus :9090  +  Grafana :3100                      │
│  (Chạy Native trên Host qua start-monitoring.sh)         │
└──────────────────────────────────────────────────────────┘
```

> **Lưu ý Networking:** Để tránh lỗi `Connection Refused` do Docker Desktop trên Linux chặn giao tiếp ngược (Host-bound), Prometheus và Grafana đã được thiết lập chạy **Native trên Host** (không bọc trong container). Grafana được auto-provision lắng nghe trên IPv4 `0.0.0.0:3100`.

---

## 🚀 1. CÁCH CHẠY DEMO TỰ ĐỘNG (KHUYÊN DÙNG)

Chúng tôi đã chuẩn bị sẵn một script tự động hóa **A-Z** mọi công đoạn. Script này vô cùng an toàn, có khả năng tự động dọn dẹp (clean) rác cũ và chạy lại luồng hoàn chỉnh bao nhiêu lần tùy thích.

```bash
# Đứng từ thư mục gốc của project
bash load-tests/run-demo.sh
```

**Script này sẽ tự động làm 5 việc theo thứ tự:**
1. **Reset Database:** Gọi API `/api/v1/dev/reset-db` (hoặc dùng Flyway) để dọn dẹp sạch sẽ dữ liệu cũ.
2. **Khởi động Backend:** Chạy Spring Boot ở background (port `8080`).
3. **Khởi động Monitoring:** Chạy Prometheus (`9090`) và Grafana (`3100`) bản Native, tự động import sẵn Dashboard JVM.
4. **Seed Dữ liệu Lớn:** Gọi kịch bản tạo 100 phòng trọ, 100 khách thuê, 80 hợp đồng, hóa đơn...
5. **Kích hoạt K6 Spike Test:** Dội bom 50 Virtual Users (VUs) vào API Dashboard.

> **Trải nghiệm Demo trực tiếp:** Ngay khi script đến bước chạy K6, hãy mở trình duyệt vào `http://localhost:3100`, đăng nhập bằng `admin` / `admin`, chọn **Dashboard -> General -> JVM (Micrometer)** và xem biểu đồ nhảy realtime!

---

## 🔄 2. CÁCH RESET VÀ CHẠY LẠI NHIỀU LẦN

Hệ thống được thiết kế hoàn toàn Idempotent (chạy nhiều lần không lỗi). 
Nếu bạn muốn biểu diễn lại cho giảng viên xem từ đầu, **chỉ cần chạy lại lệnh duy nhất:**

```bash
bash load-tests/run-demo.sh
```
Mỗi lần chạy, script sẽ tự động `kill` các process cũ bị kẹt, drop database, migrate lại từ đầu, đảm bảo môi trường hoàn toàn sạch sẽ.

---

## 🎯 3. KỊCH BẢN DEMO BẢO VỆ ĐỒ ÁN (TRƯỚC GIẢNG VIÊN)

Hãy thao tác theo kịch bản "Bật/Tắt Cache" sau đây để chứng minh sự ưu việt của hệ thống:

### Kịch bản A: Chứng minh hệ thống bị nghẽn (Khi KHÔNG có Cache)
1. Mở terminal, xóa sạch Cache Redis hiện tại:
   ```bash
   redis-cli -h localhost -p 16379 FLUSHDB
   ```
2. Chạy tay Spike Test (không gọi API trước để tránh warm-up cache):
   ```bash
   k6 run load-tests/dashboard_spike_test.js
   ```
3. **Chỉ vào Grafana:** Bạn sẽ thấy:
   - `DB Queries/s` tăng vọt.
   - `HikariCP Active Connections` bị quá tải (đạt đỉnh).
   - `http_req_duration` trên K6 terminal có thể bị delay cao.

### Kịch bản B: Chứng minh giải pháp Cache thành công
1. Gọi API Dashboard đúng 1 lần duy nhất để hệ thống nạp dữ liệu vào Redis (Warm-up):
   ```bash
   # Ghi chú: Token có thể lấy từ output của seed script
   curl -H "Authorization: Bearer <TOKEN>" http://localhost:8080/api/v1/reports/dashboard-summary
   ```
2. Chạy lại Spike Test:
   ```bash
   k6 run load-tests/dashboard_spike_test.js
   ```
3. **Chỉ vào Grafana:** Bạn sẽ thấy sự khác biệt ngoạn mục:
   - `Cache Gets (hit)` tăng vọt.
   - `DB Queries/s` và `HikariCP Active` tĩnh lặng (gần bằng 0).
   - `http_req_duration p(95)` trên K6 terminal giảm xuống siêu thấp (chỉ khoảng `10ms` - `20ms`).

---

## 🛠️ 4. CHẠY THỦ CÔNG TỪNG BƯỚC (NẾU CẦN)

Nếu bạn không muốn dùng script tự động `run-demo.sh`, bạn có thể chạy tách biệt từng thành phần:

**Bước 1: Khởi động DB + Redis**
```bash
docker compose -f docker-compose.dev.yml up -d
```

**Bước 2: Khởi động Spring Boot**
```bash
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

**Bước 3: Khởi động Monitoring Stack**
```bash
# Script này tự động tải & chạy Prometheus/Grafana Native, auto-import Dashboard 11378
bash load-tests/start-monitoring.sh
```

**Bước 4: Nhồi dữ liệu**
```bash
node load-tests/seed-massive.js
```

**Bước 5: Bắn K6**
```bash
k6 run load-tests/dashboard_spike_test.js
```

---

## ⚙️ Chi tiết những thay đổi đã làm để tối ưu Performance

| File/Module | Thay đổi | Ý nghĩa thực tiễn |
|------|---------|-------------|
| `pom.xml` | Thêm `micrometer-registry-prometheus` | Expose metrics chuẩn định dạng để Prometheus cào (scrape). |
| `application-dev.yaml` | Cấu hình `/actuator/prometheus` | Bật HTTP histogram để đo độ trễ (latency), theo dõi DB connection pool. |
| `SmartRoomRentalApplication.java` | `@EnableCaching` | Bật engine Caching mặc định của Spring Boot (trỏ vào Redis). |
| `ReportService.java` | `@Cacheable(value="dashboardSummary", key=tenantId)` | Bọc Method tính toán Dashboard cực nặng. Nếu key tồn tại, Spring trả luôn Data từ RAM (Redis), bỏ qua toàn bộ logic Query DB. |
| `CacheConfig.java` | Override RedisSerializer | Fix lỗi Jackson không thể Serialize Java Records, chuyển qua dùng `JdkSerializationRedisSerializer` an toàn và nguyên bản. |
| `Grafana / Prometheus` | Native Execution | Di dời hoàn toàn khỏi Docker VM sang chạy thẳng trên Host OS để khắc phục triệt để lỗi Network Isolation/Connection Refused của Docker Desktop Linux. |

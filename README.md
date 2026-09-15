# Smart Room Rental SaaS

[![Java](https://img.shields.io/badge/Java-21-orange)]()
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.4-green)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

A **multi-tenant SaaS platform** for boarding house management in Vietnam. Built with **Modular Monolith** architecture using Spring Boot.

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [API Documentation](#-api-documentation)
- [Project Structure](#-project-structure)
- [Modules](#-modules)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)

## 🏗 Architecture

```
Modular Monolith — Feature-based Clean Architecture
┌─────────────────────────────────────────────────────────┐
│  interfaces/rest  (Controllers, Request/Response DTOs)  │
├─────────────────────────────────────────────────────────┤
│  application      (Services, Commands, Results)         │
├─────────────────────────────────────────────────────────┤
│  domain           (Models, Repository Ports)            │
├─────────────────────────────────────────────────────────┤
│  infrastructure   (JPA Entities, Adapters, Mappers)     │
└─────────────────────────────────────────────────────────┘
```

Each module is self-contained with its own domain, application, infrastructure, and interface layers. Cross-module communication uses direct JPA queries (no REST calls).

## 🛠 Tech Stack

### Backend
| Layer | Technology |
|-------|-----------|
| **Runtime** | Java 21, Spring Boot 3.3 |
| **Database** | PostgreSQL 16 (Neon for cloud, local for dev) |
| **Migration** | Flyway |
| **Cache** | Redis 7 |
| **Auth** | JWT (jjwt 0.12) |
| **API Docs** | OpenAPI 3.0 / Swagger UI (springdoc) |
| **Mapping** | MapStruct 1.6 |
| **Testing** | JUnit 5, Mockito, H2 (in-memory), Testcontainers |
| **Build** | Maven with Wrapper |

### Frontend
| Layer | Technology |
|-------|-----------|
| **Framework** | React 18, Vite |
| **Styling** | Tailwind CSS (v3), clsx, tailwind-merge |
| **State Management** | Zustand |
| **Routing** | React Router DOM (v6) |
| **Icons & Charts** | Lucide React, Recharts |
| **Data Fetching** | Axios, React Query (TanStack) |

## 🚀 Quick Start

### Prerequisites

- **Java 21** (Temurin recommended)
- **Node.js 18+** (for frontend)
- **Docker & Docker Compose** (for local infrastructure)

Dự án cung cấp 2 chế độ chạy môi trường Local tùy thuộc vào thói quen của bạn:

### Option A: Fully Dockerized (Khuyến nghị)
Bạn không cần cài đặt Java hay Node.js. Chỉ cần Docker:

```bash
docker compose -f docker-compose.local.yml up -d
```
Lệnh này sẽ khởi động toàn bộ: **Postgres (port 15432), Redis (port 16379), Backend (port 8080), Frontend (port 5173)**.
- Khi bạn sửa code trong `frontend/` hoặc `backend/`, container sẽ tự động **Hot Reload**.
- Bấm `Ctrl+C` hoặc `docker compose -f docker-compose.local.yml down` để dừng.

### Option B: Hybrid (Infra on Docker, Apps Native)
Nếu bạn muốn dùng Terminal trên IDE (IntelliJ, VSCode) để chạy App:

**1. Khởi động Database & Redis:**
```bash
docker compose -f docker-compose.dev.yml up -d
```
*(Postgres chạy trên `localhost:15432`, Redis chạy trên `localhost:16379`)*

**2. Chạy Backend (Cần cài đặt Java 21):**
```bash
cd backend
chmod +x mvnw
./mvnw spring-boot:run
```
*(App backend sẽ chạy ở **http://localhost:8080**)*

**3. Chạy Frontend (Cần cài đặt Node 18+):**
```bash
cd frontend
npm install
npm run dev
```
*(App frontend sẽ chạy ở **http://localhost:5173**)*

### Access APIs
- **Frontend App**: http://localhost:5173
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **OpenAPI JSON**: http://localhost:8080/v3/api-docs

### 4. Default Demo Account

On first startup or after running the seed script, a demo account is available:

| Field | Value |
|-------|-------|
| Phone | `0911222333` |
| Password | `Demo@123456` |

Login via `POST /api/public/auth/login` to get a JWT token.

## 📖 API Documentation

### Swagger UI
- **Dev**: http://localhost:8080/swagger-ui.html
- **OpenAPI JSON**: http://localhost:8080/v3/api-docs

### Authentication Flow

```bash
# 1. Register (creates Manager + Tenant workspace)
curl -X POST http://localhost:8080/api/public/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"tenantName":"My Hostel","fullName":"Nguyen Van A","phone":"0901234567","password":"Pass1234"}'

# 2. Login
curl -X POST http://localhost:8080/api/public/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"identity":"0901234567","password":"Pass1234"}'

# 3. Use the returned token
curl http://localhost:8080/api/motels \
  -H 'Authorization: Bearer <your-jwt-token>'
```

### Response Format

All API responses follow a standardized envelope:

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "Optional message",
  "data": { ... },
  "timestamp": "2026-05-10T00:00:00Z"
}
```

Paginated responses wrap data in:

```json
{
  "data": {
    "content": [...],
    "page": 0,
    "size": 20,
    "totalElements": 42,
    "totalPages": 3
  }
}
```

## 📁 Project Structure

```
backend/src/main/java/com/roomrental/
├── SmartRoomRentalApplication.java
├── common/                          # Shared kernel
│   ├── config/       AppProperties
│   ├── dto/          ApiResponse, PageResponse
│   ├── entity/       BaseEntity (JPA Auditing)
│   ├── exception/    BaseException, GlobalExceptionHandler
│   ├── security/     JwtTokenService, JwtAuthFilter, TenantContextFilter
│   └── util/         SecurityUtils, TenantContext
├── config/                          # Spring configurations
│   ├── ApplicationConfig
│   ├── JpaAuditingConfig
│   ├── OpenApiConfig
│   └── SecurityConfig
├── interfaces/rest/                 # Public endpoints
│   └── controller/   HealthController
└── modules/
    ├── auth/          # Authentication & Registration
    ├── motel/         # Boarding house management
    ├── room/          # Room management
    ├── service/       # Utility service management (Electric, Water, etc.)
    ├── device/        # Device/equipment management
    ├── resident/      # Resident (renter) management
    └── technician/    # Technician management
```

## 📦 Modules

| Module | API Prefix | Use Cases | Description |
|--------|-----------|-----------|-------------|
| **Auth** | `/api/public/auth` | UC01-06 | Registration, login, password recovery |
| **Motel** | `/api/motels` | UC20-25 | CRUD boarding houses |
| **Room** | `/api/motels/{id}/rooms` | UC26-31 | CRUD rooms, status management |
| **Service** | `/api/motels/{id}/services` | UC32-37 | Manage rental services (Electric, Water, Internet) |
| **Device** | `/api/motels/{id}/devices` | UC40-45 | Equipment inventory tracking |
| **Resident** | `/api/residents` | UC49-54 | Resident account management |
| **Technician** | `/api/technicians` | UC56-62 | Technician management, lock/reset |
| **Contract** | `/api/contracts` | UC63-69 | Contract creation, appendices, deposits, cancellation |
| **MeterReading**| `/api/v1/meter-readings` | UC70-72 | Monthly electricity/water meter reading logging |
| **Invoice** | `/api/v1/invoices` | UC73-77 | Invoice generation, void, adjustment, and listing |
| **Report** | `/api/v1/reports` | UC90-94 | Revenue, occupancy, debt reporting, and dashboard |
| **Audit** | `/api/v1/audit-logs` | UC13 | System-wide audit trail logging |

## 🧪 Testing

### Run All Tests

```bash
cd backend
./mvnw test
```

### Test Structure

```
src/test/java/
├── SmartRoomRentalApplicationTests.java   # Context load (integration)
└── modules/
    ├── auth/       AuthServiceTest         # 7 test cases
    ├── motel/      MotelServiceTest         # 4 test cases
    ├── room/       RoomServiceTest          # 4 test cases
    ├── service/    RentalServiceServiceTest # 3 test cases
    └── device/     DeviceServiceTest        # 3 test cases
```

- **Unit tests**: Mockito-based, testing service layer business logic
- **Integration test**: H2 in-memory database, full Spring context

### Test Coverage

| Module | Tests | Key Scenarios |
|--------|-------|---------------|
| Auth | 7 | Register success/fail, login success/fail, account locked |
| Motel | 4 | CRUD, pagination, tenant isolation |
| Room | 4 | Create validation, duplicate check, floor validation, delete constraints |
| Service | 3 | Create, duplicate name, invalid charge type |
| Device | 3 | Create, invalid status, soft delete |
| Common | 2 | Exception handler mapping |

## 🐳 Deployment

### Docker Compose (Production)

```bash
# Set environment variables
cp .env.example .env
# Edit .env with your database credentials

docker compose up --build
```

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_URL` | Yes | — | PostgreSQL JDBC URL |
| `DB_USERNAME` | Yes | — | DB username |
| `DB_PASSWORD` | Yes | — | DB password |
| `JWT_SECRET` | Yes | — | JWT signing secret (min 32 chars) |
| `REDIS_HOST` | No | `localhost` | Redis hostname |
| `REDIS_PORT` | No | `6379` | Redis port |
| `ADMIN_PHONE` | No | `0900000000` | Default admin phone |
| `ADMIN_PASSWORD` | No | `Admin@1234` | Default admin password |

## 🤝 Contributing

1. Follow the **4-layer module structure** for new features
2. All domain models use **pure Java** (no Lombok)
3. All entities/DTOs may use **Lombok**
4. All REST responses must use `ApiResponse<T>` wrapper
5. All paginated responses must use `PageResponse<T>`
6. Use `BaseException` static factories for error handling
7. Write unit tests for every service method

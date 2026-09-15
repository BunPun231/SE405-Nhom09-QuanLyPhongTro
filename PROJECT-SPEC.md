# Smart Room Rental SaaS - Complete Project Specification for AI Coding Agent

**Project Name:** Smart Boarding House Management System (SaaS)  
**SRS Version:** 0.5 (April 21, 2026)  
**ADD Version:** Latest (Attribute-Driven Design)  
**Purpose:** Single source of truth for GitHub Copilot / Cursor / Codex to generate accurate, production-ready code.

## 1. Project Overview

The system is a **multi-tenant SaaS web application** for managing boarding houses (phòng trọ) in Vietnam.  
It targets middle-aged landlords (Managers) with a **minimalist, step-by-step UI**.

**Core Goals:**
- Automate billing (electricity/water tiered pricing + OCR).
- Support VietQR payment with webhook auto-reconciliation.
- Strong multi-tenancy (each landlord has isolated data).
- High usability for non-technical users.

**Four Roles:**
- **ADMIN** – System-wide management
- **MANAGER** – Landlords (main user)
- **TECHNICIAN** – Maintenance staff
- **RESIDENT** – Renters

## 2. Tech Stack (Final – Aligned with ADD)

| Layer                  | Technology                                      | Reason (ADD Reference)                     |
|------------------------|-------------------------------------------------|--------------------------------------------|
| Frontend               | React + Vite + PWA + Tailwind + shadcn/ui   | QA12, QA14 (Mobile + Offline)              |
| State Management       | Zustand + TanStack Query                        | Offline queue + caching                    |
| Backend                | Spring Boot                    | QA22 (Team familiarity), QA15 (Modularity) |
| Architecture           | Modular Monolith + Clean Architecture           | Decision 1 & 8                             |
| Auth                   | Spring Security + Stateless JWT (custom)        | QA04 (No managed IAM)                      |
| Database               | Neon PostgreSQL-compatible DB + Flyway          | QA07 (ACID), QA24 (JSONB)                  |
| Caching                | Redis                                       | QA01, QA02 (Performance)                   |
| Media Storage          | Cloudinary                                      | QA25, C5 (20GB limit)                      |
| OCR                    | Google Cloud Vision API + Adapter               | QA10 (Human-in-the-loop)                   |
| Payment                | VietQR Webhook + Adapter Pattern                | QA06                                       |
| Notification           | Resend + Firebase FCM + Outbox Pattern          | QA11                                       |
| Resiliency             | Resilience4j                                    | QA07, QA11                                 |
| Mapping                | MapStruct                                       | Development speed                          |
| Observability          | Actuator + Micrometer + Prometheus/Grafana      | QA16                                       |
| Testing                | JUnit + Testcontainers + Mockito              | QA23 (>80% coverage)                       |
| Deployment             | Docker + Docker Compose                         | QA21, QA26                                 |
| CI/CD                  | GitHub Actions                                  | Build time < 5 min                         |



## 3. Key Architectural Decisions (from ADD)

- **Modular Monolith + Clean Architecture** (Domain → Application → Infrastructure → Interfaces)
- **Multi-tenancy**: Shared DB + `TenantContext` + global filter (custom-built, no managed IAM)
- **Stateless backend** (JWT + Redis)
- **Append-only versioning** for contracts & financial trail
- **JSONB** for Calculation Snapshots and Tenant Config
- **Adapter Pattern** for all 3rd-party integrations
- **Bounded @Async thread pool** (< 5 threads) for batch jobs
- **Optimistic Locking** (@Version) for concurrency
- **Transactional Outbox** for notifications

**Hard Constraints (ADD):**
- VPS: 2 vCPU / 2GB RAM
- Budget: $0 (only free tiers)
- Timeline: 8 weeks (56 days)
- Team: 2 developers

5. Project Folder Structure
Root
smart-room-rental-saas/
├── backend/                  # Spring Boot Modular Monolith
├── frontend/                 # React PWA
├── docker/                   # Docker Compose & production scripts
├── .env.example
├── docker-compose.yml
├── README.md
└── PROJECT-SPEC.md           # This file
└── .gitignore
Backend structure (Clean Architecture + feature-based modular monolith):


backend/
├── src/
│   └── main/
│       ├── java/
│       │   └── com/
│       │       └── roomrental/
│       │           ├── SmartRoomRentalApplication.java
│       │           │
│       │           ├── common/                  # Cross-cutting concerns
│       │           │   ├── config/              # Framework configs, @ConfigurationProperties
│       │           │   ├── exception/           # BaseException, GlobalExceptionHandler
│       │           │   ├── security/            # JWT utilities + Multi-tenancy filter
│       │           │   └── util/                # TenantContext, helpers
│       │           │
│       │           ├── modules/                 # Business modules by bounded context
│       │           │   ├── core/                # Shared business core split by feature
│       │           │   │   ├── auth/             # Login/Register + workspace tenant bootstrap
│       │           │   │   │   ├── domain/
│       │           │   │   │   │   ├── model/
│       │           │   │   │   │   └── repository/
│       │           │   │   │   ├── application/
│       │           │   │   │   │   ├── dto/
│       │           │   │   │   │   └── service/
│       │           │   │   │   ├── infrastructure/
│       │           │   │   │   │   ├── entity/
│       │           │   │   │   │   ├── mapper/
│       │           │   │   │   │   ├── repository/
│       │           │   │   │   │   ├── adapter/
│       │           │   │   │   │   └── outbox/
│       │           │   │   │   └── interfaces/
│       │           │   │   │       └── rest/
│       │           │   │   │           ├── controller/
│       │           │   │   │           └── dto/
│       │           │   │   ├── user/             # User profile / account management (future)
│       │           │   │   │   ├── domain/
│       │           │   │   │   ├── application/
│       │           │   │   │   ├── infrastructure/
│       │           │   │   │   └── interfaces/rest/
│       │           │   │   └── tenant/          # Workspace tenant lifecycle/settings (future)
│       │           │   │       ├── domain/
│       │           │   │       ├── application/
│       │           │   │       ├── infrastructure/
│       │           │   │       └── interfaces/rest/
│       │           │   ├── billing/             # Invoice, MeterReading, CalculationSnapshot
│       │           │   │   ├── domain/
│       │           │   │   ├── application/
│       │           │   │   └── infrastructure/
│       │           │   │       └── outbox/
│       │           │   ├── contract/            # Contract, ContractVersion, Appendix
│       │           │   │   ├── domain/
│       │           │   │   ├── application/
│       │           │   │   └── infrastructure/
│       │           │   │       └── outbox/
│       │           │   ├── motel/                # Motel, Room, Service
│       │           │   │   ├── domain/
│       │           │   │   ├── application/
│       │           │   │   └── infrastructure/
│       │           │   │       └── outbox/
│       │           │   ├── maintenance/         # MaintenanceTicket, MaintenanceDetail
│       │           │   │   ├── domain/
│       │           │   │   ├── application/
│       │           │   │   └── infrastructure/
│       │           │   │       └── outbox/
│       │           │   ├── notification/        # NotificationEvent, Outbox
│       │           │   │   ├── domain/
│       │           │   │   ├── application/
│       │           │   │   └── infrastructure/
│       │           │   │       └── outbox/
│       │           │   └── device/              # Device, DeviceUsage, DeviceMovementLog
│       │           │       ├── domain/
│       │           │       ├── application/
│       │           │       └── infrastructure/
│       │           │           └── outbox/
│       │           │
│       │           └── config/                  # ApplicationConfig, SecurityConfig, AsyncConfig...
│       │
│       ├── resources/
│       │   ├── application.yml
│       │   ├── application-dev.yml
│       │   ├── application-prod.yml
│       │   ├── db/
│       │   │   └── migration/                   # Flyway SQL scripts (centralized)
│       │   ├── static/
│       │   └── templates/
│       │
│       └── docker/
│           └── Dockerfile
│
├── pom.xml
├── mvnw
└── mvnw.cmd



Frontend structure:

frontend/
├── src/
│   ├── app/                          # App router + global layout
│   │   ├── layout.tsx
│   │   ├── providers.tsx             # TenantProvider, QueryClientProvider...
│   │   └── globals.css
│   │
│   ├── components/                   # UI components
│   │   ├── ui/                       # shadcn/ui components (button, table, dialog...)
│   │   ├── common/                   # Reusable (DataTable, StepWizard, OfflineIndicator...)
│   │   └── features/                 # Feature-specific (MeterReader, InvoicePreview...)
│   │
│   ├── features/                     # Feature-Sliced Design (FSD) approach
│   │   ├── auth/                     # Login, Registration, Password Recovery
│   │   ├── contracts/                # Contract Management, Appendices, Deposits
│   │   ├── dashboard/                # Main Overview Dashboard
│   │   ├── invoices/                 # Billing, Invoice Generation, Payments
│   │   ├── meter/                    # Electric & Water Meter Readings
│   │   ├── motels/                   # Boarding Houses & Rooms
│   │   ├── reports/                  # Revenue, Occupancy, Debt Analytics
│   │   ├── residents/                # Tenant Management
│   │   ├── services/                 # Rental Services (Electric, Water, etc.)
│   │   └── settings/                 # System & Profile Settings
│   │
│   ├── hooks/                        # Custom hooks
│   │   ├── useAuth.ts
│   │   ├── useTenant.ts
│   │   ├── useOfflineQueue.ts
│   │   └── useQuery.ts
│   │
│   ├── lib/
│   │   ├── api.ts                    # Axios instance + tenant interceptor
│   │   ├── utils.ts
│   │   ├── validators.ts
│   │   └── offlineStorage.ts         # IndexedDB queue
│   │
│   ├── pages/                        # Legacy / Shared page components (most pages are inside features)
│   │   ├── onboarding/               # Step-by-step wizard
│   │
│   ├── store/                        # Zustand stores
│   │   ├── tenantStore.ts
│   │   ├── authStore.ts
│   │   └── offlineQueueStore.ts
│   │
│   ├── service-worker/               # PWA
│   │   └── registerSW.ts
│   │
│   ├── assets/
│   ├── styles/
│   └── types/                        # Global TypeScript types
│
├── public/
│   ├── manifest.json
│   └── icons/
│
├── vite.config.ts
├── tailwind.config.ts
├── components.json                   # shadcn/ui config
├── package.json
├── tsconfig.json
├── .env.example
└── Dockerfile

DOCKER & DEPLOYMENT:
docker/
├── Dockerfile.backend
├── Dockerfile.frontend
├── nginx.conf                        # (optional) reverse proxy
├── entrypoint.sh
└── healthcheck.sh

Deployment notes:
- Neon is the managed database layer, so local deployment no longer requires a PostgreSQL container.
- All Spring Boot runtime settings should come from environment variables in `.env.example`.
- Redis is still containerized for local development and VPS deployment.


8. Coding Guidelines for AI Agent

Follow Clean Architecture strictly.
Multi-tenancy: Every query must go through TenantContext.getCurrentTenantId().
Security: All protected endpoints require valid JWT + tenant validation.
Error Handling: Use custom exceptions + message codes (MSG01, MSG98…).
Performance: Use Redis cache for configs & dashboard. Prefer database aggregation over in-memory processing.
OCR: Always store confidence_score, ocr_raw_result, ocr_provider. Implement PENDING if confidence < 90%.
Notifications: Use Transactional Outbox Pattern.
Testing: Write domain service unit tests first (no Spring context).
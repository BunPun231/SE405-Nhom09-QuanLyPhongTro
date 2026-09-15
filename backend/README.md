# Backend — Smart Room Rental SaaS

## Prerequisites

- **Java 21** (Temurin/Corretto)
- **Docker** (for PostgreSQL + Redis)
- Maven 3.9+ (included via `mvnw`)

## Development Setup

### 1. Start Infrastructure

```bash
# From repo root
docker compose -f docker-compose.dev.yml up -d
```

This provisions:
| Service | Port | Credentials |
|---------|------|-------------|
| PostgreSQL 16 | 5432 | `rental_dev` / `rental_dev_pass` / DB: `rental_management` |
| Redis 7 | 6379 | No auth |

### 2. Run Application

```bash
./mvnw spring-boot:run
```

- Profile: `dev` (auto-detected)
- Flyway will automatically run migrations
- Admin account seeded on first run (`0900000000` / `Admin@1234`)

### 3. Verify

```bash
curl http://localhost:8080/api/public/health
# {"success":true,"code":"SUCCESS","data":{"status":"UP"},"timestamp":"..."}
```

## Key Endpoints

| Endpoint | Description |
|----------|-------------|
| `http://localhost:8080/swagger-ui.html` | 📖 Swagger UI |
| `http://localhost:8080/v3/api-docs` | OpenAPI 3.0 JSON spec |
| `http://localhost:8080/actuator/health` | Health check |

## Configuration

| Profile | File | Purpose |
|---------|------|---------|
| `dev` | `application-dev.yaml` | Local PostgreSQL + Redis, SQL logging |
| `prod` | `application-prod.yaml` | Cloud DB (Neon), minimal logging |
| `test` | `application-test.yaml` | H2 in-memory, no Redis, no bootstrap |

## Architecture

```
modules/<module>/
├── domain/           # Pure Java models + Repository ports (interfaces)
│   ├── model/        # Domain entities (no JPA annotations)
│   └── repository/   # Port interfaces
├── application/      # Use case implementation
│   ├── dto/          # Command/Result records
│   └── service/      # Application services
├── infrastructure/   # Technical implementation
│   ├── entity/       # JPA entities (Lombok + BaseEntity)
│   ├── repository/   # Spring Data JPA repositories
│   ├── adapter/      # Repository port implementations
│   ├── mapper/       # MapStruct mappers (Entity ↔ Domain)
│   └── bootstrap/    # Data seeders
└── interfaces/       # API layer
    └── rest/
        ├── controller/ # REST controllers
        └── dto/        # Request/Response records
```

## Conventions

| Area | Convention |
|------|-----------|
| Domain models | Pure Java (no Lombok, no JPA) |
| Entities/DTOs | Lombok (`@Getter @Setter @NoArgsConstructor`) |
| Soft delete | `@SQLRestriction("is_deleted = false")` on entity |
| Audit | Extend `BaseEntity` for `createdAt`/`updatedAt` |
| Responses | Always wrap in `ApiResponse<T>` |
| Pagination | Use `PageResponse<T>` with Spring `Pageable` |
| Errors | Throw `BaseException` (use static factories) |
| Naming | `*Command` (input), `*Result` (output), `*Request` (REST) |

## Running Tests

```bash
# All tests
./mvnw test

# Specific module
./mvnw test -Dtest="com.roomrental.modules.auth.**"

# With coverage report
./mvnw test jacoco:report
# Report at: target/site/jacoco/index.html
```

## Useful Maven Commands

```bash
# Compile only
./mvnw compile

# Package (skip tests)
./mvnw package -DskipTests

# Clean build
./mvnw clean install

# Run with specific profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=prod
```

## Notes

- Multi-tenant context is resolved from JWT `tenantId` claim (not header-based)
- Flyway migrations: `src/main/resources/db/migration/`
- `database.sql` in `src/main/resources/db/` is the reference schema (not used at runtime)

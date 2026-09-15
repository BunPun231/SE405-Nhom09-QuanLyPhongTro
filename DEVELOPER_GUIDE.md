# Developer Guide

## 1. Mục tiêu kiến trúc
Project này đi theo mô hình **Modular Monolith** kết hợp **Clean Architecture**.

- **Modular Monolith**: một ứng dụng deploy duy nhất, nhưng code được chia theo module nghiệp vụ.
- **Clean Architecture**: mỗi module tách rõ các lớp:
  - **Domain**: mô hình nghiệp vụ thuần, không phụ thuộc framework.
  - **Application**: use case, orchestration, rule nghiệp vụ ứng dụng.
  - **Infrastructure**: JPA, Redis, JWT, mapper, persistence adapter, external integration.
  - **API / Interfaces**: REST controller, request/response DTO, validation, Swagger annotations.

Quy tắc chung: dependency chỉ đi từ ngoài vào trong. Domain không được biết JPA, Spring, Redis hay HTTP là gì.

## 2. Cấu trúc thư mục backend
Backend tổ chức theo package feature-based.

- `com.roomrental.common`: tiện ích dùng chung, security, exception, config, tenant context.
- `com.roomrental.modules.core`: các năng lực lõi dùng chung cho toàn hệ thống, ví dụ `auth`, `tenant`, `user`.
- `com.roomrental.modules.finance`: module nghiệp vụ tài chính.
- `com.roomrental.modules.contract`: module hợp đồng.
- `com.roomrental.modules.property`: module tài sản / khu trọ / căn hộ.
- `com.roomrental.modules.motel`: module khu trọ hiện tại.

Trong từng module, nên giữ cấu trúc tương tự:

- `domain/`
- `application/`
- `infrastructure/`
- `interfaces/rest/`

Ví dụ:

- `modules/motel/domain/model/Motel.java`
- `modules/motel/application/service/MotelService.java`
- `modules/motel/infrastructure/persistence/MotelEntity.java`
- `modules/motel/interfaces/rest/controller/MotelController.java`

## 3. Quy ước giao tiếp giữa các module
Các module nghiệp vụ như **Finance**, **Contract**, **Property** phải giao tiếp theo nguyên tắc sau để tránh phụ thuộc chéo:

- Không import trực tiếp entity, repository, controller, hoặc DTO nội bộ của module khác.
- Chỉ giao tiếp qua **application service**, **public domain contract**, hoặc **event**.
- Nếu cần dữ liệu từ module khác, hãy khai báo một **port/interface** ở module cần dùng, rồi module kia triển khai adapter nếu thật sự cần.
- Không cho phép module A truy cập thẳng repository JPA của module B.
- Không cho phép module A tự đọc bảng database của module B bằng native query, trừ khi có lý do rất rõ ràng và được review kỹ.
- Khi cần phối hợp nghiệp vụ, ưu tiên:
  - gọi service công khai của module khác,
  - hoặc phát domain event / integration event,
  - hoặc dùng shared contract tối thiểu.

Ví dụ đúng:

- `ContractService` gọi port `PropertyLookupPort` để lấy thông tin property.
- `Finance` nhận event `ContractSignedEvent` để sinh hóa đơn.

Ví dụ sai:

- `FinanceService` import trực tiếp `ContractEntity`.
- `PropertyController` query repository của `Finance`.

## 4. Multi-tenancy
Project dùng multi-tenancy theo kiểu **row-level tenant isolation**.

Nguyên tắc:

- Mỗi bản ghi nghiệp vụ phải có `tenant_id`.
- Mọi truy vấn đọc/ghi phải lọc theo `tenant_id`.
- Không bao giờ tin dữ liệu tenant do client gửi trực tiếp nếu chưa đối chiếu với JWT.

Luồng chuẩn:

1. JWT từ Clerk phải có claim chứa tenant, ví dụ `tenant_id` hoặc `tenantId`.
2. Security filter đọc JWT, trích giá trị tenant và đẩy vào `TenantContext`.
3. Application service lấy tenant hiện tại từ `TenantContext`.
4. Repository luôn filter theo `tenant_id`.

Quy ước triển khai:

- Filter/adapter chỉ nên set `TenantContext` một lần ở tầng security.
- Service nghiệp vụ luôn gọi helper kiểu `requireTenantId()` trước khi thao tác DB.
- Repository method nên có dạng `findByIdAndTenantIdAndDeletedFalse(...)`, `findByTenantIdAndDeletedFalse(...)`, hoặc tương đương.
- Bất kỳ update/delete nào cũng phải kiểm tra tenant trước khi thay đổi dữ liệu.

Nếu tích hợp Clerk trong tương lai, hãy map claim tenant của Clerk vào context nội bộ của app, không rải logic Clerk khắp codebase.

## 5. Update API & Partial Updates
Quy ước hiện tại là dùng **PATCH** cho các thao tác update để dễ dùng hơn và nhất quán với Swagger/UI.

- `POST` cho create.
- `PATCH` cho update từng tài nguyên.
- `DELETE` cho soft delete hoặc xóa logic.

Khi thêm update API mới, ưu tiên `@PatchMapping` thay vì `@PutMapping` nếu không cần thay thế toàn bộ resource.

### Partial Updates (PATCH)
**PATCH endpoint hỗ trợ partial updates** — chỉ cần gửi các field cần thay đổi, không cần gửi toàn bộ object.

Cách triển khai:

1. **Tạo DTO riêng cho PATCH** nếu validation khác với POST:
   - DTO POST (create) thường có `@NotBlank`, `@NotNull` bắt buộc.
   - DTO PATCH nên có các validation **flexible**, cho phép null nếu field là optional.
   - Ví dụ: `MotelPatchRequestBody` có tất cả field nullable (không bắt buộc).

2. **Controller**:
   ```java
   @PatchMapping("/{id}")
   public ResponseEntity<MotelResult> patch(
       @PathVariable Long id, 
       @Valid @RequestBody MotelPatchRequestBody body) {
       return ResponseEntity.ok(motelService.patch(id, toPatchCommand(body)));
   }
   ```

3. **Service**: Chỉ update các field không null:
   ```java
   if (command.name() != null) {
       motel.setName(command.name());
   }
   if (command.address() != null) {
       motel.setAddress(command.address());
   }
   // ... tương tự cho các field khác
   ```

4. **Swagger test**:
   ```json
   // Chỉ cần gửi field muốn thay đổi
   {
       "name": "Khu trọ mới"
   }
   // Các field khác (address, totalFloors, description) sẽ KHÔNG bị thay đổi
   ```

**Lợi ích**:
- Giảm payload (gửi ít dữ liệu hơn).
- Tránh lỗi validation khi client quên field bắt buộc.
- Flexible hơn cho mobile app hay dynamic form.

## 6. Swagger / API docs
Swagger UI đã được cấu hình để hỗ trợ JWT bearer token.

- Dùng nút `Authorize` để dán access token sau khi login.
- Các endpoint bảo vệ bởi JWT nên khai báo security requirement.
- Ví dụ login được gắn sẵn giá trị mẫu để dev mới thử nhanh.

Luồng kiểm tra nhanh:

1. Mở Swagger UI.
2. Gọi `/api/public/auth/login`.
3. Copy `accessToken` trả về.
4. Bấm `Authorize` và dán token vào.
5. Gọi các endpoint cần quyền, ví dụ motel CRUD.

## 7. Seed admin mặc định
Project có cơ chế seed admin mặc định khi app khởi động.

Cấu hình nằm trong `.env` hoặc biến môi trường:

- `ADMIN_BOOTSTRAP_ENABLED`
- `ADMIN_TENANT_CODE`
- `ADMIN_TENANT_NAME`
- `ADMIN_FULL_NAME`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`

Giá trị mặc định hiện tại:

- tenant code: `admin`
- email: `admin@gmail.com`
- password: `Admin@1234`

Seeder phải idempotent:

- Chạy nhiều lần không tạo bản ghi trùng.
- Nếu tenant/account đã tồn tại thì bỏ qua.

## 8. Unit test standard
Mục tiêu là giữ coverage **trên 80%** cho phần backend quan trọng.

Chuẩn viết test:

- Dùng **JUnit 5** cho test framework.
- Dùng **Mockito** để mock dependency của application service.
- Test class nên đặt cùng package logic với class cần test.
- Tên test nên mô tả behavior, không mô tả implementation.
- Tách rõ Arrange / Act / Assert.
- Không để unit test phụ thuộc database thật.

Phạm vi nên ưu tiên test:

- `application/service`
- mapper
- domain rule
- security helper nếu có logic thuần

Không nên dùng unit test để thay thế integration test.

Gợi ý:

- Unit test: mock repository/port, kiểm tra service logic.
- Integration test: dùng `@SpringBootTest`, H2 hoặc Testcontainers nếu cần validate JPA/Flyway.

Tiêu chuẩn tối thiểu:

- Logic mới phải có test đi kèm.
- Không merge nếu coverage của module tụt xuống dưới 80% mà không có lý do rõ ràng.
- Test cần ổn định, không phụ thuộc thứ tự chạy.

## 9. Cấu hình `.env` cho Neon DB
Backend hiện chạy với Neon PostgreSQL. File `.env` ở root nên chứa ít nhất các biến sau:

```env
SPRING_PROFILES_ACTIVE=prod
DB_URL=jdbc:postgresql://<neon-host>/<database>?sslmode=require
DB_USERNAME=<neon-username>
DB_PASSWORD=<neon-password>
JWT_SECRET=<at-least-32-bytes-secret>
JWT_ACCESS_TOKEN_MINUTES=60
TENANT_HEADER_NAME=X-Tenant-Id
REDIS_HOST=redis
REDIS_PORT=6379
ADMIN_BOOTSTRAP_ENABLED=true
ADMIN_TENANT_CODE=admin
ADMIN_TENANT_NAME=Room Rental Admin
ADMIN_FULL_NAME=System Administrator
ADMIN_EMAIL=admin@roomrental.local
ADMIN_PASSWORD=Admin@1234
```

Lưu ý:

- Không commit secret thật lên git.
- Nếu chạy Docker Compose local, `.env` ở root sẽ được nạp vào `docker-compose.yml`.
- Khi đổi Neon database hoặc password, cập nhật lại `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` tương ứng.

## 10. Quy trình làm việc khuyến nghị
Khi thêm tính năng mới:

1. Xác định module chủ sở hữu nghiệp vụ.
2. Thiết kế domain trước.
3. Viết application service/use case.
4. Thêm persistence adapter nếu cần.
5. Tạo REST API ở `interfaces/rest`.
6. Viết unit test cho service và mapper.
7. Chạy build và kiểm tra Docker nếu liên quan runtime.

## 11. Event-Driven Async Logging

Hệ thống sử dụng kiến trúc **Event-Driven Asynchronous Logging** để đảm bảo hiệu năng và tuân thủ **Clean Architecture** (Single Responsibility Principle). Các Business Service tuyệt đối **không** gọi trực tiếp các logging service (như `ActivityLogService` hay `AuditLogService`). Thay vào đó, chúng chỉ cần phát ra các **Domain Event**.

Quy trình tích hợp logging vào module/API mới:

1. **Định nghĩa Domain Event:**
   - Tạo một `record` implements interface `LoggableEvent` (nằm trong `com.roomrental.common.event`).
   - Khai báo các field cần thiết và implement các phương thức bắt buộc: `tenantId`, `actorId`, `actorRole`, `action`, `entityType`, `entityId`.
   - Ghi đè (override) các phương thức mặc định nếu cần lưu thêm thông tin: `oldValue()`, `newValue()`, `metadata()`.
   - Ví dụ:
     ```java
     public record ContractActivatedEvent(
             UUID tenantId, UUID actorId, String actorRole, Long contractId
     ) implements LoggableEvent {
         @Override public String action() { return "ACTIVATE_CONTRACT"; }
         @Override public String entityType() { return "Contract"; }
         @Override public String entityId() { return contractId.toString(); }
     }
     ```

2. **Phát Event trong Business Service:**
   - Inject `ApplicationEventPublisher`.
   - Sử dụng `eventPublisher.publishEvent(new YourEvent(...))` vào cuối luồng xử lý nghiệp vụ thành công.
   - Hệ thống sẽ đảm bảo không làm gián đoạn transaction chính.

3. **Cơ chế hoạt động ngầm (Developer không cần viết thêm):**
   - `DomainEventPublisher` (chạy đồng bộ trên thread chính) sẽ lắng nghe `LoggableEvent`, tự động trích xuất `IP Address` và `User-Agent` từ HTTP Request hiện tại, bọc thành `EnrichedLogEvent` và phát đi.
   - Các Listener bất đồng bộ (`ActivityLogListener`, `SecurityAuditLogListener`) chạy trên thread pool tối ưu hóa (`log-async-`) sẽ bắt lấy `EnrichedLogEvent` và ghi xuống DB (`activity_logs`, `audit_logs`).

**Lưu ý quan trọng cho Security Audit Log:**
Nếu sự kiện của bạn mang tính nhạy cảm về bảo mật (ví dụ: `USER_LOGIN`, `PASSWORD_RESET`, `LOCK_USER`), bạn phải thêm giá trị `action` của event đó vào hằng số `SECURITY_ACTIONS` nằm trong lớp `SecurityAuditLogListener`. Nếu không, hệ thống sẽ chỉ ghi dưới dạng Activity Log thông thường.

## 12. Checklist nhanh cho dev mới
- Hiểu module mình cần sửa thuộc `core`, `finance`, `contract`, hay `property`.
- Không import chéo entity/repository giữa module.
- Luôn lọc theo `tenant_id`.
- Dùng `PATCH` cho update resource.
- Thêm test mới cho logic mới.
- Chạy `./mvnw -DskipTests clean package` trước khi push thay đổi lớn.

## 13. Frontend Architecture & Conventions
Frontend được xây dựng dựa trên **React 18 + Vite** theo kiến trúc **Feature-Sliced Design** (FSD) kết hợp với **Clean Architecture** (cấp độ UI).

### Cấu trúc thư mục (`frontend/src/`)
- `app/`: Các thiết lập toàn cục, routing (`routes.tsx`), context providers (`providers.tsx`), global CSS.
- `components/`:
  - `ui/`: Các UI primitives dùng chung (Button, Input, Modal, Table).
  - `layout/`: Các thành phần layout (Sidebar, Header, MainLayout).
- `features/`: Chia theo từng module nghiệp vụ (auth, motels, residents, contracts, invoices, meter, reports, settings).
  - Bên trong mỗi feature có các thư mục: `pages/` (màn hình chính), `components/` (các UI/modal riêng biệt cho feature đó).
- `store/`: Quản lý state toàn cục bằng Zustand (ví dụ: `authStore.ts`).
- `data/`: Dữ liệu mock (`mock.ts`) để phục vụ quá trình phát triển UI MVP.
- `lib/`: Các hàm tiện ích (utils, formatCurrency, cn).
- `types/`: Định nghĩa Typescript cho toàn bộ Domain Model (User, Motel, Room, Invoice...).

### Quy ước viết Code (Frontend)
1. **Component Design**: 
   - Sử dụng React Functional Components (RFC) + Hooks.
   - Các components phức tạp phải được bóc tách từ các UI primitives cơ bản (`src/components/ui/`).
   - Mọi class CSS nên được xử lý qua hàm `cn(...)` (`clsx` + `tailwind-merge`) để xử lý xung đột.
2. **State Management**:
   - Dữ liệu global (User Session, Tenant Info) dùng `Zustand`.
   - Dữ liệu fetch từ server (sẽ tích hợp sau) dùng `React Query`.
3. **Styling**:
   - Tuân thủ Tailwind CSS. Hạn chế dùng inline styles (`style={{}}`).
   - Sử dụng các token màu sắc từ config (`brand-deep`, `brand-warm`, `brand-ink`, `brand-sand`).
4. **Mock Data**:
   - Hiện tại sử dụng `src/data/mock.ts` cho MVP Demo.
   - Khi nối API, hãy thay thế các import mock bằng hook của React Query gọi qua Axios/Fetch api client.

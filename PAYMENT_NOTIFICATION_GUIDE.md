# HƯỚNG DẪN CẤU HÌNH & KIỂM THỬ MODULE THANH TOÁN (VIETQR / SEPAY) VÀ THÔNG BÁO (NOTIFICATION / FCM / WEBSOCKET)

Tài liệu này hướng dẫn chi tiết cách thiết lập các dịch vụ bên ngoài (SePay, VietQR, Firebase FCM) và cách gọi thử nghiệm (test) các API tương ứng trong dự án **Smart Room Rental SaaS**.

---

## 1. PHÂN HỆ THANH TOÁN (PAYMENT & VIETQR)

Hệ thống sử dụng **VietQR** để hiển thị mã QR động chứa số tiền, tài khoản thụ hưởng của khu trọ (Motel), nội dung chuyển khoản tự động (Memo code) và tích hợp **SePay.vn Webhook** để nhận diện biến động số dư tự động đồng bộ hóa hóa đơn ngay lập tức.

### A. Thiết lập trên SePay.vn (Cổng Webhook)
1. Đăng ký tài khoản và đăng nhập vào trang quản trị [SePay.vn](https://sepay.vn).
2. Kết nối tài khoản ngân hàng của bạn (hoặc tài khoản ngân hàng của chủ trọ nhận tiền thanh toán).
3. Tạo một **Webhook** mới trên SePay hướng về Server của bạn:
   - **URL Webhook**: `https://<ten-mien-hoac-ngrok-cua-ban>/api/v1/payments/webhook`
   - **Phương thức (Method)**: `POST`
   - **Loại định dạng**: JSON
   - **Mã bảo mật (API Key)**: Nhập một chuỗi ký tự bảo mật bất kỳ (ví dụ: `MySuperSecretSepayKey123`).
4. Cấu hình biến môi trường trên Server (trong file `.env` hoặc cấu hình hệ thống):
   ```env
   SEPAY_API_KEY=MySuperSecretSepayKey123
   ```
   *(Lưu ý: Nếu không cấu hình `SEPAY_API_KEY`, Endpoint Webhook sẽ không yêu cầu Header Authorization phục vụ mục đích test cục bộ).*

---

### B. Luồng hoạt động & Kiểm thử (Testing)

#### Bước 1: Khai báo tài khoản ngân hàng cho Khu Trọ (Motel)
Mỗi khu trọ cần khai báo ngân hàng nhận tiền riêng của mình để sinh mã VietQR động chính xác.
- Đăng nhập tài khoản **Manager (Quản lý)**.
- Gửi Request tạo mới hoặc cập nhật khu trọ với cấu hình ngân hàng (`bank_config`):
  - **API**: `PUT /api/v1/motels/{id}` hoặc `POST /api/v1/motels`
  - **Payload Body (JSON)**:
    ```json
    {
      "name": "Khu Trọ Bình Dân Tân Phú",
      "address": "123 Lũy Bán Bích, Tân Phú, HCM",
      "electricityPrice": 3500,
      "waterPrice": 15000,
      "bankConfig": {
        "bankBin": "970415", 
        "bankNumber": "1903657849102",
        "accountName": "NGUYEN VAN A"
      }
    }
    ```
    *(Ghi chú: `bankBin` là mã BIN ngân hàng gồm 6 số, ví dụ `970415` cho Vietcombank, `970407` cho Techcombank, tham khảo danh sách mã BIN tại [VietQR.io](https://vietqr.io)).*

#### Bước 2: Lấy thông tin thanh toán & mã VietQR của Hóa Đơn (Invoice)
Khi Tenant (Người thuê) muốn thanh toán hóa đơn, Client gọi API sau để lấy thông tin VietQR:
- **API**: `GET /api/v1/invoices/{invoiceId}/payment-info`
- **Response trả về (JSON)**:
  ```json
  {
    "amount": 2500000.00,
    "bankBin": "970415",
    "bankNumber": "1903657849102",
    "accountName": "NGUYEN VAN A",
    "memo": "PT25",
    "qrUrl": "https://img.vietqr.io/image/970415-1903657849102-compact2.png?amount=2500000.00&addInfo=PT25&accountName=NGUYEN%20VAN%20A"
  }
  ```
  - **Frontend UI** sẽ hiển thị thẻ `<img>` trỏ nguồn đến thuộc tính `qrUrl` để hiển thị QR Code động cho khách thuê quét mã thanh toán bằng ứng dụng ngân hàng.

#### Bước 3: Giả lập / Test Webhook SePay (Simulating SePay Webhook)
Khi khách thuê quét mã thành công, SePay sẽ bắn một request POST về server. Bạn có thể kiểm tra luồng xử lý tự động này bằng Postman hoặc Curl:
- **API**: `POST /api/v1/payments/webhook`
- **Headers**:
  ```http
  Content-Type: application/json
  Authorization: Apikey MySuperSecretSepayKey123
  ```
- **Request Body (JSON)**:
  ```json
  {
    "id": 998877,
    "gateway": "Techcombank",
    "transferType": "in",
    "transferAmount": 2500000.00,
    "code": "PT25",
    "content": "NGUYEN VAN B CHUYEN TIEN PHONG TRO PT25",
    "referenceCode": "FT26172635",
    "transferDate": "2026-06-18 19:40:00"
  }
  ```
  *(Thay thế `code` hoặc `content` chứa mã hóa đơn là `PT<invoiceId>`, ví dụ `PT25` ứng với hóa đơn ID là `25`).*

- **Kết quả mong đợi**:
  - Webhook trả về trạng thái `200 OK` kèm JSON:
    ```json
    {
      "success": true,
      "message": "Payment processed successfully for Invoice ID: 25"
    }
    ```
  - Trạng thái hóa đơn `25` được chuyển đổi tự động sang `PAID`.
  - Một giao dịch thanh toán (Transaction) tự động lưu vào cơ sở dữ liệu.
  - Người thuê nhận được thông báo biến động số dư / xác nhận thanh toán trực tiếp qua Websocket và FCM Push.

---

## 2. PHÂN HỆ THÔNG BÁO (NOTIFICATION / FCM / WEBSOCKET)

Thông báo hoạt động theo 2 cơ chế song song:
1. **Real-time WebSocket (In-App)**: Hiển thị thông báo ngay lập tức trên trình duyệt khi người dùng đang hoạt động.
2. **Firebase Cloud Messaging (FCM Push)**: Đẩy thông báo về thiết bị di động (Mobile App) ngay cả khi không mở ứng dụng.

### A. Thiết lập Firebase Cloud Messaging (FCM)
Để kích hoạt thông báo đẩy thực tế:
1. Truy cập vào [Firebase Console](https://console.firebase.google.com/).
2. Tạo một Project mới hoặc chọn Project sẵn có.
3. Đi tới mục **Project Settings** > **Service accounts** (Tài khoản dịch vụ).
4. Nhấp vào nút **Generate new private key** (Tạo khóa riêng tư mới). Tệp cấu hình dạng `.json` sẽ được tải về.
5. Đặt tệp JSON này vào thư mục của bạn hoặc định nghĩa biến môi trường:
   - Lưu vào: `backend/src/main/resources/firebase-service-account.json`
   - **HOẶC** Chỉ định biến môi trường `.env`:
     ```env
     FIREBASE_CREDENTIALS_PATH=/duong/dan/toi/tep/firebase-service-account.json
     ```
   *(Nếu không tìm thấy file này, hệ thống sẽ log cảnh báo và bỏ qua việc gửi Push về FCM, các luồng WebSocket và Lưu DB vẫn chạy bình thường).*

---

### B. Kiểm thử APIs và Kết Nối Real-time

#### 1. Đăng ký nhận thông báo real-time qua WebSockets (STOMP client)
Kết nối đến cổng WebSocket trên client:
- **Địa chỉ kết nối (Websocket Endpoint)**: `ws://localhost:8080/ws` (hoặc qua HTTP sử dụng SockJS fallback).
- **Subscribe Topic (Đăng ký nhận kênh riêng tư)**:
  - Địa chỉ: `/queue/notifications-{userId}`
  - Trong đó `{userId}` là ID tài khoản người dùng đăng nhập hiện tại (ví dụ: `/queue/notifications-3`).
- **Nội dung tin nhắn nhận được tự động khi có sự kiện**:
  ```json
  {
    "id": 101,
    "title": "Hóa đơn mới",
    "content": "Hóa đơn tháng 06/2026 phòng 101 đã được khởi tạo. Số tiền: 2,500,000đ.",
    "type": "INVOICE_CREATED",
    "read": false,
    "createdAt": "2026-06-19T10:00:00"
  }
  ```

#### 2. Đăng ký Token thiết bị của thiết bị di động (FCM Token Registration)
Mỗi khi người dùng đăng nhập trên điện thoại di động, App cần gửi FCM Token lên server để lưu lại:
- **API**: `POST /api/v1/notifications/tokens`
- **Headers**:
  ```http
  Authorization: Bearer <JWT_ACCESS_TOKEN>
  Content-Type: application/json
  ```
- **Request Body (JSON)**:
  ```json
  {
    "token": "d1hX_yZa8-2K1X...your_fcm_registration_token...",
    "deviceType": "ANDROID"  // Hoặc "IOS", "WEB"
  }
  ```

#### 3. Đọc danh sách thông báo cá nhân (In-app Notification List)
- **API**: `GET /api/v1/notifications`
- **Headers**:
  ```http
  Authorization: Bearer <JWT_ACCESS_TOKEN>
  ```
- **Query Parameters (Phân trang)**:
  - `page` (Mặc định: `0`)
  - `size` (Mặc định: `20`)
- **Phản hồi**: Trả về danh sách thông báo phân trang của riêng user đó.

#### 4. Đánh dấu đã đọc thông báo (Mark as Read)
Đánh dấu một thông báo cụ thể là đã đọc:
- **API**: `PUT /api/v1/notifications/{notificationId}/read`
- **Headers**:
  ```http
  Authorization: Bearer <JWT_ACCESS_TOKEN>
  ```

Đánh dấu toàn bộ thông báo của bản thân là đã đọc:
- **API**: `PUT /api/v1/notifications/read-all`
- **Headers**:
  ```http
  Authorization: Bearer <JWT_ACCESS_TOKEN>
  ```

---

## 3. CƠ CHẾ DỌN DẸP TỰ ĐỘNG & BẢO TRÌ (CLEANUP & RETRY)
- **FCM Outbox processor**: Hệ thống chạy ngầm một tác vụ quét bảng `notification_outbox` mỗi **60 giây** để đẩy thông báo chưa gửi đến Firebase FCM, tránh làm chậm luồng xử lý chính. Nếu xảy ra lỗi Token không hợp lệ hoặc đã hết hạn, hệ thống sẽ tự động dọn dẹp và xóa Token lỗi đó khỏi cơ sở dữ liệu.
- **Dọn dẹp lịch sử**: Cứ mỗi **3 giờ sáng**, hệ thống sẽ tự động chạy tiến trình ngầm để xóa toàn bộ các thông báo đã đọc được tạo trước đó trên **30 ngày** nhằm tối ưu hóa bộ nhớ cơ sở dữ liệu.

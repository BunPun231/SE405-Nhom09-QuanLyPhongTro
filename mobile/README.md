# 📱 Smart Room Rental SaaS - Mobile Application (Flutter)

Ứng dụng di động quản lý phòng trọ cao cấp được phát triển bằng **Flutter**, mô phỏng và chuyển thể từ thiết kế UI mẫu `Simple Sample App`.

## 🌟 Tính năng chính theo 4 Vai trò (Multi-role System)

### 1. 🏠 Tenant (Người thuê trọ)
- **Trang chủ (Tenant Home)**: Xem thông tin phòng đang thuê, hạn hợp đồng, hóa đơn chưa thanh toán.
- **Thanh toán VietQR**: Tự động hiển thị mã QR động để quét chuyển khoản qua ứng dụng ngân hàng.
- **Báo sự cố (Maintenance)**: Gửi báo cáo hư hỏng kèm mô tả, theo dõi tiến độ sửa chữa thực tế.
- **Hợp đồng (Contract)**: Xem thông tin hợp đồng đặt cọc, tiền nhà, quy định phòng.
- **Tài khoản (Profile)**: Quản lý thông tin cá nhân và cài đặt ứng dụng.

### 2. 🏢 Manager (Chủ trọ / Quản lý khu trọ)
- **Dashboard tổng quan**: Thống kê doanh thu, tỷ lệ lấp đầy phòng, thông báo biến động số dư.
- **Quản lý phòng (Rooms)**: Danh sách phòng, bộ lọc trạng thái (Đang ở, Trống, Đang sửa chữa).
- **Chỉ số Điện/Nước (Utility Reading)**: Ghi chỉ số công tơ điện nước hàng tháng nhanh chóng.
- **Hóa đơn & VietQR (Invoices)**: Lập hóa đơn, theo dõi hóa đơn đã thanh toán/quá hạn, cài đặt VietQR nhận tiền.
- **Xử lý sự cố (Maintenance)**: Tiếp nhận yêu cầu từ người thuê và giao việc cho kỹ thuật viên.
- **Khách thuê & Hợp đồng**: Quản lý danh sách khách thuê và hợp đồng hết hạn.

### 3. 🛠️ Technician (Kỹ thuật viên)
- **Danh sách công việc**: Xem công việc sửa chữa được giao, cập nhật trạng thái (Chờ xử lý, Đang làm, Hoàn thành).
- **Thiết bị (Equipment)**: Kiểm tra danh mục thiết bị và lịch bảo trì.

### 4. 👑 System Admin (Quản trị hệ thống)
- **Tổng quan SaaS**: Thống kê số lượng tòa nhà, chủ trọ, khách thuê toàn hệ thống.
- **Quản lý người dùng**: Quản lý tài khoản, phân quyền sử dụng.

---

## 🚀 Cấu trúc dự án Flutter (`lib/`)

```

`API_BASE_URL` mặc định là `10.0.2.2:8080` cho Android Emulator. Khi dùng
điện thoại thật, thay `192.168.1.x` bằng IPv4 Wi-Fi của máy tính chạy Backend.
Backend phải lắng nghe trên `0.0.0.0:8080` và tường lửa Windows phải cho phép
kết nối TCP đến cổng 8080.
lib/
├── main.dart                      # Entry point ứng dụng
├── core/
│   ├── constants/
│   │   └── app_colors.dart        # Hệ màu UI & gradient
│   ├── theme/
│   │   └── app_theme.dart         # Material 3 Theme (Light/Dark)
│   └── models/
│       └── app_models.dart        # Data Models (Role, Room, Invoice, Maintenance, Tenant)
└── presentation/
    ├── widgets/
    │   ├── mobile_header.dart     # Header động với nút chuyển Vai trò
    │   ├── mobile_bottom_nav.dart # Thanh điều hướng dưới tương ứng từng vai trò
    │   └── role_selector_dialog.dart # Modal đổi nhanh vai trò (Manager/Tenant/Tech/Admin)
    └── screens/
        ├── main_navigation_screen.dart # Frame màn hình chính
        ├── manager/               # Màn hình cho Chủ trọ
        ├── tenant/                # Màn hình cho Khách thuê
        ├── technician/            # Màn hình cho Kỹ thuật viên
        └── admin/                 # Màn hình cho Admin
```

---

## 💻 Hướng dẫn chạy ứng dụng

1. Đảm bảo đã cài đặt **Flutter SDK** (PHIÊN BẢN 3.0+).
2. Di chuyển vào thư mục `mobile`:
   ```bash
   cd mobile
   ```
3. Tải các gói phụ thuộc:
   ```bash
   flutter pub get
   ```
4. Chạy ứng dụng trên thiết bị mô phỏng (iOS Simulator / Android Emulator / Web):
   ```bash
   flutter run
   ```
### Hai Android app độc lập (product flavors)

Flavor `manager` dùng entrypoint quản lý (`lib/main.dart`), application ID
`com.example.room_rental_mobile`, tên hiển thị **QL Nhà Trọ**. Flavor `gate`
dùng entrypoint kiosk (`lib/main_gate.dart`), application ID
`com.example.room_rental_mobile.gate`, tên hiển thị **Kiosk Cổng**.

```bash
# Chạy app quản lý
flutter run --flavor manager -t lib/main.dart

# Chạy kiosk (mặc định camera trước)
flutter run --flavor gate -t lib/main_gate.dart

# Chạy kiosk trên điện thoại thật cùng Wi-Fi với Backend
flutter run --flavor gate -t lib/main_gate.dart --dart-define=API_BASE_URL=http://<IP_MAY_TINH>:8080

# Build hai APK độc lập
flutter build apk --release --flavor manager -t lib/main.dart
flutter build apk --release --flavor gate -t lib/main_gate.dart
```

Màn hình đăng ký khuôn mặt mặc định dùng camera sau; màn hình kiosk mặc định
dùng camera trước. Nút `flip_camera_android` ở góc trên cho phép đổi camera
trong lúc demo hoặc bảo trì.

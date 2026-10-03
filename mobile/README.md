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

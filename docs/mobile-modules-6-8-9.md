# Module 6, 8, 9 trên app mobile

Nhánh: `feature/mobile-modules-6-8-9` (tách từ `main`). Nhánh `main` giữ nguyên UI cũ để so sánh.

Đặc tả nguồn: file "Danh sách usecase + timeline Đồ án 2.xlsx" (sheet *Danh sách usecase* và *US*), đối chiếu thêm `SRS.md`.

## Cách so sánh với UI cũ

```bash
git diff main..feature/mobile-modules-6-8-9 --stat
```

Chạy UI mới:

```bash
git switch feature/mobile-modules-6-8-9
cd mobile && flutter run --flavor manager -t lib/main.dart
```

Muốn xem UI cũ thì `git switch main` rồi chạy lại lệnh `flutter run` ở trên. Backend cũng phải chạy từ cùng nhánh, vì màn hình mới cần các API và trường dữ liệu mới. Lần đầu chạy backend sẽ tự áp dụng migration `V33`, `V34`.

## Màn hình mới nằm ở đâu

| Module | Vào từ menu | Code chính |
|---|---|---|
| VI Khách thuê (UC49–55) | Khách thuê | `screens/manager/manager_tenants_screen.dart`, `screens/manager/tenants/` |
| VIII Hợp đồng (UC63–68) + Cọc (UC69) + Tất toán (UC80) | Hợp đồng | `screens/manager/manager_contracts_screen.dart`, `screens/manager/contracts/`, `screens/tenant/tenant_contract_screen.dart` |
| IX Chỉ số điện nước (UC70–72) | Ghi số Điện Nước | `screens/manager/manager_utility_reading_screen.dart`, `screens/manager/meter/`, `screens/tenant/meter/` |
| IX Hóa đơn & Thanh toán (UC73–79) | Hóa đơn & VietQR | `screens/manager/manager_invoices_screen.dart`, `screens/manager/invoices/`, `screens/tenant/invoices/`, `widgets/invoice_detail_sheet.dart` |

## Mức độ hoàn thành

Đã làm hầu hết AC trong sheet US. Các phần chưa trọn:

| UC | Còn thiếu |
|---|---|
| UC53 | Chưa có luồng "yêu cầu chỉnh sửa" họ tên/CCCD (thuộc UC07/UC08, ngoài phạm vi). Hai trường này đang chỉ đọc. |
| UC55 | Khóa đăng nhập hoàn toàn khi hợp đồng kết thúc, đúng AC của US55. **Cần nhóm quyết định**, vì SRS BR80/BR55.4 muốn khách cũ vẫn xem được hóa đơn nợ (`role_scope: FORMER`). |
| UC49/51 | Ảnh CCCD và avatar đang lưu dạng base64 trong DB, chưa dùng storage riêng có signed URL như BR49.5. |
| UC63 | Bước tạo hợp đồng và bước thu cọc là 2 lệnh gọi API, chưa nằm trong một giao dịch. Nếu bước thu cọc lỗi, hợp đồng ở trạng thái "Chờ thu cọc". |
| UC64 | Tìm theo tên/phòng chỉ tìm trên các trang đã tải (app có báo và có nút "Tải thêm"). |
| UC67 | Chưa tự chuyển sang tất toán; chưa ghi cọc bị mất vào "thu nhập khác" (BR67.5). |
| UC68 | PDF dùng font Helvetica nên chữ **không dấu**; chưa gửi qua email. |
| UC70 | Backend chưa kiểm tra khách thuê chỉ gửi/xem được phòng của mình (BR70.1, BR72.1). |
| UC71 | Chưa giới hạn 5 lần OCR mỗi tháng (BR71.8) và chưa ghi audit cho OCR (BR71.9). |
| UC72 | "Lọc theo khách thuê" đang làm qua lọc phòng. |
| UC73 | Chưa bỏ qua phòng sắp trả trong kỳ (BR73.9). Chưa xác minh việc giới hạn theo khu trọ của quản lý (BR73.1). |
| UC78 | Khi nội dung chuyển khoản sai, webhook chưa đưa giao dịch vào "Chờ đối soát" (BR78.7). |
| UC80 | Hợp đồng chưa tự thanh lý khi webhook báo đã trả hóa đơn tất toán (quản lý phải bấm "Thanh lý"). Chưa tự tạo phiếu bảo trì khi có hư hỏng. |

## Thay đổi backend đáng chú ý

- Migration mới: `V33__resident_profile_extra_fields.sql`, `V34__meter_reading_reject_reason.sql`.
- API hủy hợp đồng chặt hơn trước: bắt buộc có lý do, chặn khi còn nợ hoặc đã có hóa đơn được thanh toán. Script `frontend/scripts/clean.js` có thể không hủy được hợp đồng seed đã có hóa đơn.
- `GET /api/v1/payments/transactions`: sửa lỗi khách thuê xem được giao dịch của khách khác trong cùng khu.
- `POST /api/v1/invoices/generate` có thêm chế độ chạy đồng bộ để trả kết quả cho app.
- Endpoint mới: tìm kiếm/lịch sử/tổng quan khách thuê, đính kèm và hóa đơn của hợp đồng, xem/chốt tất toán, chỉ số cũ của phòng.

## Kiểm thử đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | 0 lỗi; còn 1 cảnh báo có từ trước (`service_service.dart`). Trước khi làm có 9 cảnh báo. |
| `flutter test` | 64 pass, 1 lỗi. Test lỗi là `test/widget_test.dart`, file mẫu "Counter" mặc định của Flutter, có từ trước và nhánh này không sửa. |
| `./mvnw test` | 75/75 pass, gồm test khởi động toàn bộ ứng dụng. |
| `flutter build apk --debug --flavor manager` | Thành công. |

**Chưa kiểm tra:** chạy app trên máy thật hoặc emulator với backend và database có dữ liệu.

**Lưu ý môi trường:** `flutter test` và `flutter build` lỗi khi chạy trực tiếp trong thư mục `D:\Mobile&Pervasive\...` vì ký tự `&` trong đường dẫn. Phải chép thư mục `mobile/` sang một đường dẫn không có `&` rồi mới chạy.

## Đề xuất dọn dẹp sau

- Thêm vào `AppColors` màu xác nhận `#059669` và các màu chữ trạng thái đậm (`#047857`, `#B45309`, `#B91C1C`). Mỗi module đang tự khai báo tạm.
- Gom các helper định dạng tiền, ngày và `StatusBadge` vào `core/utils`.
- `PageResponse` của mobile đọc khóa `number` trong khi backend trả `page`.
- `ApiClient.delete` nên nhận `params`.
- Xóa các hàm chỉ số điện nước cũ trong `invoice_service.dart`, vì màn hình đã chuyển sang `meter_reading_service.dart`.

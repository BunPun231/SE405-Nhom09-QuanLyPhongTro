# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Hai nhóm người dùng chính, quan trọng ngang nhau trên app mobile:

- **Chủ trọ (Manager):** chủ khu trọ quy mô nhỏ ở Việt Nam, đa số ở độ tuổi trung niên và không rành công nghệ (SRS). Dùng app để quản lý khu trọ và phòng, chốt chỉ số điện nước hằng tháng, lập và theo dõi hóa đơn, tiếp nhận sự cố và giao cho kỹ thuật viên, quản lý khách thuê và hợp đồng.
- **Khách thuê (Tenant / Resident):** người đang thuê phòng. Xem phòng, hợp đồng và hóa đơn; thanh toán bằng VietQR; báo sự cố kèm mô tả và theo dõi tiến độ sửa; đăng ký khuôn mặt để qua cổng.

Nhóm phụ:

- **Kỹ thuật viên (Technician):** xem việc sửa chữa được giao, cập nhật trạng thái, xem thiết bị theo phòng và theo loại.
- **Quản trị hệ thống (Admin):** theo dõi toàn hệ thống SaaS, quản lý người dùng và gói dịch vụ.

## Product Purpose

Chuyển việc quản lý phòng trọ từ sổ sách, giấy tờ và Excel sang nền tảng số: tự động tính tiền điện nước (kể cả biểu giá bậc thang), tổng hợp hóa đơn kèm nợ cũ, thanh toán qua VietQR có đối soát tự động, và lưu tập trung lịch sử hợp đồng, thanh toán.

App được dùng thật hằng ngày cho khu trọ, không chỉ để demo. Thành công nghĩa là chủ trọ không rành công nghệ vẫn tự làm được các việc hằng tháng mà không sai số liệu, và khách thuê tự xem, thanh toán hóa đơn, báo sự cố mà không phải nhắn tin qua lại với chủ trọ.

## Positioning

Theo khảo sát trong SRS: phần mềm trả phí (Mona House, QuanLyTro, iTro) có phí bản quyền cao so với chủ trọ nhỏ 10–20 phòng; phần mềm miễn phí hoặc giá rẻ (Lazido) chỉ quản lý thu chi chung chung, nhiều quảng cáo, bố trí chức năng khó dùng với người mới.

Sản phẩm này làm đúng các nghiệp vụ đặc thù Việt Nam mà các app chung chung bỏ qua: giá điện nước lũy tiến, thiết bị gắn theo từng phòng, quy trình tất toán trừ cọc theo hư hỏng thiết bị, kết hợp đọc đồng hồ bằng OCR và thanh toán VietQR tự đối soát. Chi phí vận hành bám free tier.

## Operating Context

- **Chu kỳ hằng tháng:** chốt chỉ số điện/nước → hệ thống tạo hóa đơn (tiền phòng + dịch vụ + nợ cũ) → khách quét VietQR chuyển khoản → webhook ngân hàng tự cập nhật trạng thái hóa đơn.
- **Sự cố:** khách báo hỏng kèm ảnh → chủ trọ phân công kỹ thuật viên → kỹ thuật viên cập nhật trạng thái (Đã kiểm tra → Đang sửa → Chờ linh kiện → Hoàn thành) và chụp ảnh xác nhận.
- **Hai app Android riêng (product flavor):**
  - **QL Nhà Trọ** (`manager`, `lib/main.dart`): app đa vai trò; đăng nhập xong vào giao diện theo vai trò (chủ trọ, khách thuê, kỹ thuật viên, admin).
  - **Kiosk Cổng** (`gate`, `lib/main_gate.dart`): thiết bị đặt ở cổng khu trọ, chạy toàn màn hình, khóa dọc, dùng camera trước để quét khuôn mặt cư dân và mở cổng. Khuôn mặt được đăng ký trước trong app khách thuê (mặc định camera sau).
- Kết nối backend Spring Boot qua REST (`API_BASE_URL`); dữ liệu tách riêng theo từng chủ trọ (multi-tenant).

## Capabilities and Constraints

- Flutter, Material 3, chỉ phát hành Android. iOS chưa cấu hình và không nằm trong phạm vi.
- Giao diện tiếng Việt, tiền tệ VND.
- Nhận diện khuôn mặt chạy trên máy (Google ML Kit + MobileFaceNet TFLite).
- Thuật ngữ: Khu trọ, Phòng, Khách thuê / Cư dân, Hợp đồng, Hóa đơn, Chỉ số điện/nước, Dịch vụ, Sự cố / Bảo trì, Tất toán, Kỹ thuật viên.
- Trạng thái phòng: Trống, Đã cọc, Đang thuê, Đang sửa chữa. Trạng thái hóa đơn: Còn nợ, Thanh toán một phần, Đã thanh toán (SRS).
- OCR đọc đồng hồ (SRS UC71): kết quả dưới 90% độ tin cậy phải chờ người xác nhận; quá 5 giây thì chuyển sang nhập tay. Người dùng luôn được sửa trước khi lưu.
- Khách thuê đã trả phòng (`role_scope: FORMER`) chỉ thấy lịch sử hóa đơn và hợp đồng; ẩn báo hỏng, thanh toán kỳ tới, danh sách thành viên (SRS BR55.5).
- Ràng buộc dự án: ngân sách $0 (chỉ free tier), nhóm phát triển nhỏ.
- **Chưa quyết định:** chế độ tối (dark mode) cho app quản lý. Hiện app chỉ dùng theme sáng; Kiosk Cổng dùng nền tối.

## Brand Commitments

- Tên sản phẩm: Smart Room Rental SaaS. Tên hiển thị trên Android: **QL Nhà Trọ** (app quản lý) và **Kiosk Cổng** (app cổng).
- Giọng văn: tiếng Việt, đơn giản, rõ ràng cho người không rành công nghệ (SRS).
- Chưa có logo hay bộ nhận diện thương hiệu trong app mobile.

## Evidence on Hand

- Tài liệu nghiệp vụ: `../SRS.md`, `../PROJECT-SPEC.md`, `README.md`.
- Ảnh thiết kế màn hình theo vai trò (Admin, Kỹ thuật viên, Khách thuê…) trong `../frontend/design/`, làm cho bản web.
- Chưa có số liệu người dùng thật, đánh giá, testimonial hay số liệu sử dụng. Không được bịa các nội dung này.

## Product Principles

1. **Người không rành công nghệ phải tự làm được.** Luồng quan trọng (tạo hợp đồng, tất toán, chốt chỉ số) đi từng bước, mỗi bước ít lựa chọn, giảm tối đa nhập sai.
2. **Tiền phải minh bạch và chính xác.** Mọi con số trên hóa đơn truy được nguồn (chỉ số, đơn giá bậc thang, nợ cũ); trạng thái thanh toán cập nhật ngay khi ngân hàng báo.
3. **Máy gợi ý, người quyết định.** OCR và nhận diện khuôn mặt chỉ điền sẵn hoặc cảnh báo; người dùng luôn xác nhận hoặc sửa được trước khi lưu.
4. **Mỗi vai trò chỉ thấy việc của mình.** Chủ trọ, khách thuê và kỹ thuật viên có giao diện riêng; dữ liệu của mỗi chủ trọ tách biệt hoàn toàn.

## Accessibility & Inclusion

- Ưu tiên chủ trọ trung niên ít rành công nghệ: chữ dễ đọc, nút dễ chạm, luồng thao tác tinh gọn, nhãn chữ rõ ràng thay vì chỉ có biểu tượng (SRS).
- Chưa xác định chuẩn tiếp cận bắt buộc (ví dụ WCAG).

---
name: QL Nhà Trọ
description: App Android quản lý phòng trọ cho chủ trọ và khách thuê; rõ ràng, chính xác như một cuốn sổ thu chi được giữ gọn.
colors:
  royal-blue: "#2563EB"
  confirm-green: "#059669"
  collected-green: "#10B981"
  pending-amber: "#F59E0B"
  overdue-red: "#EF4444"
  deposit-violet: "#8B5CF6"
  ink-slate: "#0F172A"
  heading-slate: "#1E293B"
  muted-slate: "#64748B"
  faint-slate: "#94A3B8"
  hairline-slate: "#E2E8F0"
  mist-slate: "#F1F5F9"
  paper-slate: "#F8FAFC"
  white: "#FFFFFF"
typography:
  headline:
    fontFamily: "Roboto, sans-serif"
    fontSize: "22sp"
    fontWeight: 700
    letterSpacing: "-0.5px"
  title-large:
    fontFamily: "Roboto, sans-serif"
    fontSize: "18sp"
    fontWeight: 700
    letterSpacing: "-0.3px"
  title:
    fontFamily: "Roboto, sans-serif"
    fontSize: "15sp"
    fontWeight: 700
  button:
    fontFamily: "Roboto, sans-serif"
    fontSize: "14sp"
    fontWeight: 700
    letterSpacing: "-0.2px"
  body:
    fontFamily: "Roboto, sans-serif"
    fontSize: "13sp"
    fontWeight: 400
  label:
    fontFamily: "Roboto, sans-serif"
    fontSize: "12sp"
    fontWeight: 600
  caption:
    fontFamily: "Roboto, sans-serif"
    fontSize: "11sp"
    fontWeight: 400
  micro:
    fontFamily: "Roboto, sans-serif"
    fontSize: "10sp"
    fontWeight: 700
rounded:
  badge: "8dp"
  control-sm: "10dp"
  tile: "12dp"
  control: "14dp"
  card: "16dp"
  pill: "20dp"
  sheet: "28dp"
spacing:
  xs: "4dp"
  sm: "8dp"
  md: "12dp"
  lg: "16dp"
  xl: "20dp"
  2xl: "24dp"
components:
  button-primary:
    backgroundColor: "{colors.royal-blue}"
    textColor: "{colors.white}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "14dp 20dp"
  button-confirm:
    backgroundColor: "{colors.confirm-green}"
    textColor: "{colors.white}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "14dp 20dp"
  button-outlined:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink-slate}"
    typography: "{typography.button}"
    rounded: "{rounded.control}"
    padding: "14dp 20dp"
  input-field:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink-slate}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "14dp 16dp"
  chip-filter:
    backgroundColor: "{colors.white}"
    textColor: "{colors.muted-slate}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "8dp 14dp"
  chip-filter-selected:
    backgroundColor: "{colors.royal-blue}"
    textColor: "{colors.white}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "8dp 14dp"
  status-badge:
    backgroundColor: "rgba(16, 185, 129, 0.10)"
    textColor: "{colors.collected-green}"
    typography: "{typography.micro}"
    rounded: "{rounded.badge}"
    padding: "3dp 8dp"
  card:
    backgroundColor: "{colors.white}"
    rounded: "{rounded.card}"
    padding: "16dp"
  icon-tile:
    backgroundColor: "rgba(37, 99, 235, 0.10)"
    textColor: "{colors.royal-blue}"
    rounded: "{rounded.tile}"
    size: "44dp"
  nav-item-active:
    backgroundColor: "rgba(37, 99, 235, 0.08)"
    textColor: "{colors.royal-blue}"
    typography: "{typography.micro}"
    rounded: "{rounded.tile}"
    padding: "6dp 10dp"
  bottom-sheet:
    backgroundColor: "{colors.white}"
    rounded: "{rounded.sheet}"
---

# Design System: QL Nhà Trọ

Phạm vi: app quản lý **QL Nhà Trọ** (flavor `manager`, `lib/main.dart`). App **Kiosk Cổng** (flavor `gate`) dùng một theme tối riêng khai báo trong `lib/main_gate.dart` và không thuộc hệ token này. Mọi kích thước là logical pixel của Flutter: dp cho khoảng cách và bo góc, sp cho cỡ chữ vì chữ co giãn theo cỡ chữ hệ thống. Nguồn token trong code: `lib/core/constants/app_colors.dart` và `lib/core/theme/app_theme.dart`.

## Overview

**Creative North Star: "Sổ thu chi gọn gàng"**

App là cuốn sổ thu chi của khu trọ, được giữ ngăn nắp. Nhân vật chính trên mỗi màn hình là con số và trạng thái: tiền phòng, chỉ số điện nước, hóa đơn đã thu hay còn nợ, phòng trống hay đang thuê. Phần còn lại lùi về sau: nền giấy sáng, thẻ trắng viền mảnh, chữ xám cho ghi chú. Màu xuất hiện khi có điều cần báo, như dấu bút đỏ hay dấu tích xanh trong sổ.

Cảm giác mong muốn là đáng tin cậy, sáng sủa thoáng đãng, hiện đại và chuyên nghiệp, đủ để chủ trọ yên tâm về tiền và khách thuê thấy minh bạch. Hình khối mềm mại, dễ gần: bo góc lớn, biểu tượng đặt trên nền màu nhạt, bóng đổ gần như vô hình. Mật độ vừa phải, mỗi thẻ là một mục trong sổ.

Giao diện không được giống app miễn phí rối mắt (quảng cáo, banner, bố trí lộn xộn), cũng không giống app mạng xã hội hay game (nhiều màu, hiệu ứng, gradient rực rỡ).

**Key Characteristics:**
- Nền Paper Slate, thẻ trắng viền mảnh, bóng đổ chỉ thoảng qua.
- Một màu hành động duy nhất (Xanh hoàng gia); các màu còn lại đều mang nghĩa trạng thái.
- Trạng thái hiện bằng nền nhạt cộng chữ hoặc biểu tượng đậm cùng màu.
- Bo góc lớn và nhất quán theo bậc: 8 → 10 → 12 → 14 → 16 → 20 → 28.
- Font hệ thống Roboto, chữ đậm cho tiêu đề và con số, xám cho mọi thứ phụ.

## Colors

Bảng màu Slate lạnh và sáng, với một màu xanh hoàng gia cho hành động và một bộ màu trạng thái có nghĩa cố định.

### Primary
- **Xanh hoàng gia** (royal-blue): nút chính, tab và chip đang chọn, viền ô nhập khi focus, liên kết, chữ cái đại diện trong avatar. Khi làm nền, nó được pha loãng 8–12% (ô biểu tượng, mục điều hướng đang chọn, nhãn kênh).

### Secondary
- **Xanh lá xác nhận** (confirm-green): chỉ dùng cho nút xác nhận liên quan đến tiền: duyệt chỉ số, đánh dấu hóa đơn đã thu, thanh toán. Đây là "dấu tích" của cuốn sổ, tách khỏi Xanh hoàng gia để hành động chốt tiền luôn nhận ra được.

### Tertiary
Bộ màu trạng thái, mỗi màu một nghĩa:
- **Xanh lá đã thu** (collected-green): đã thanh toán, hoàn thành, đang thuê, xu hướng tốt.
- **Cam chờ xử lý** (pending-amber): chờ duyệt, đang sửa chữa, hợp đồng sắp hết hạn.
- **Đỏ quá hạn** (overdue-red): nợ, quá hạn, lỗi, xóa, chấm thông báo chưa đọc.
- **Tím đặt cọc** (deposit-violet): phòng đã đặt cọc, khoản cọc.

### Neutral
- **Mực đen xám** (ink-slate): tiêu đề trang, tiêu đề app bar, chữ trên nút viền.
- **Xám tiêu đề** (heading-slate): tên mục trong thẻ (số phòng, tên khách), giá trị trong dòng thông tin.
- **Xám ghi chú** (muted-slate): chữ phụ, nhãn, gợi ý trong ô nhập, biểu tượng chưa chọn. Đây là màu chữ dùng nhiều nhất sau màu chính.
- **Xám mờ** (faint-slate): ngày tháng, meta, trạng thái ngừng hoạt động.
- **Xám đường kẻ** (hairline-slate): viền ô nhập, viền nút, viền thẻ, đường chia app bar và thanh điều hướng.
- **Xám sương** (mist-slate): viền thẻ nội dung mềm hơn, nền khối phụ, skeleton khi tải.
- **Nền giấy** (paper-slate): nền mọi màn hình, nền chip chưa chọn trong theme.
- **Trắng thẻ** (white): thẻ, bottom sheet, header, thanh điều hướng, ô nhập.

### Named Rules
**The Meaning-Only Color Rule.** Ngoài Xanh hoàng gia cho hành động, mỗi màu khác phải mang một nghĩa trạng thái trong bảng trên. Không dùng màu để trang trí hay phân biệt danh mục cho vui mắt.

**The Tint-Not-Fill Rule.** Trạng thái hiện bằng nền pha loãng 8–12% cùng chữ hoặc biểu tượng đậm cùng màu. Nền đặc chỉ dành cho nút chính, nút xác nhận và chip đang chọn.

## Typography

**Display Font:** Roboto (font hệ thống Android)
**Body Font:** Roboto (font hệ thống Android)
**Label/Mono Font:** monospace hệ thống, chỉ cho mã số (mã hóa đơn `#123`)

**Character:** Một họ font duy nhất, phân cấp bằng độ đậm và màu thay vì đổi font. Đậm cho tiêu đề và con số, thường cho nội dung, xám cho mọi thứ phụ.

### Hierarchy
- **Headline** (700, 22sp, letterSpacing -0.5): tiêu đề lớn đầu màn hình tổng quan.
- **Title Large** (700, 18sp, -0.3): tiêu đề app bar, tiêu đề bottom sheet, giá trị KPI.
- **Title** (700, 15sp): tên mục trong thẻ, như "Phòng 101".
- **Button** (700, 14sp, -0.2): chữ trên nút.
- **Body** (400, 13sp): nội dung, chữ trong ô nhập, gợi ý, nhãn ô nhập.
- **Label** (600, 12sp): chữ trên chip, dòng phụ trong thẻ, nhãn trong dòng thông tin.
- **Caption** (400, 11sp): ngày tháng, meta.
- **Micro** (700, 10sp): nhãn trạng thái, nhãn thanh điều hướng (đậm khi chọn, thường khi chưa chọn).

### Named Rules
**The Number-First Rule.** Trong một dòng hoặc thẻ, con số người dùng cần (tiền, chỉ số, số phòng) đậm hơn và lớn hơn nhãn đi kèm. Nhãn luôn ở Xám ghi chú.

## Layout

Bố cục điện thoại dọc, một cột. Lề màn hình 16dp, đáy danh sách chừa 32dp. Khoảng cách giữa các khối theo bậc 8 / 12 / 16 / 20, thường gặp nhất là 12–20 giữa các khối và 4–8 trong một khối. Thẻ trong danh sách cách nhau 12dp. Chỉ số KPI xếp lưới 2 cột với khe 10dp.

Khung mỗi vai trò gồm: header tùy biến ở trên (nút menu, avatar, tên, chuông thông báo), nội dung cuộn ở giữa, thanh điều hướng 3–4 mục ở dưới. Header và thanh điều hướng tự xử lý vùng an toàn bằng `SafeArea`. Chưa có bố cục riêng cho máy tính bảng hay màn hình ngang.

## Elevation & Depth

Phẳng khi đứng yên. Viền mảnh (Xám đường kẻ hoặc Xám sương) làm việc phân tách chính; bóng đổ chỉ thoảng qua để thẻ tách nhẹ khỏi nền giấy. App bar, nút và thẻ trong theme đều có elevation 0.

### Shadow Vocabulary
- **Bóng thẻ** (đen 3–4%, blur 8, lệch y 2): thẻ nội dung, khối doanh thu.
- **Bóng thẻ danh sách** (đen 4%, blur 10, lệch y 4): thẻ phòng có thể chạm.
- **Bóng thanh điều hướng** (đen 12%, blur 8, lệch y -2): tách thanh điều hướng dưới khỏi nội dung.
- **Quầng chip chọn** (Xanh hoàng gia 25%, blur 8, lệch y 3): chỉ cho chip lọc đang chọn.

### Named Rules
**The Whisper Shadow Rule.** Bóng đổ phải gần như không thấy (đen tối đa 4% trên thẻ). Bóng có màu chỉ dành cho trạng thái đang chọn, không bao giờ để trang trí.

## Shapes

Hình khối mềm, bo góc lớn theo bậc cố định: nhãn trạng thái 8, nút biểu tượng và avatar 10, ô biểu tượng và mục điều hướng 12, nút và ô nhập 14, thẻ 16, chip 20 (dạng viên thuốc), mép trên bottom sheet 28. Thanh tiến độ và tay kéo dùng bo 2–4. Avatar là ô vuông bo 10 chứa chữ cái đầu của tên gọi (từ cuối trong họ tên), không phải hình tròn; chấm trạng thái trực tuyến và chấm thông báo là hình tròn.

Thẻ nội dung trong các màn hình hiện dùng lẫn 16, 18 và 20; theme chuẩn là 16.

## Components

### Buttons
Mềm, phẳng, chắc tay.
- **Shape:** bo vừa (14dp), elevation 0.
- **Primary:** nền Xanh hoàng gia, chữ trắng, Button 14sp đậm, đệm 14 × 20dp.
- **Confirm:** như Primary nhưng nền Xanh lá xác nhận, chỉ cho hành động chốt tiền (duyệt chỉ số, đã thu, thanh toán).
- **Outlined:** nền trắng, viền Xám đường kẻ, chữ Mực đen xám 600.
- **Text:** nút chữ cho hành động phụ (hủy, xem thêm).
- **Icon button trong header:** ô 36 × 36dp, nền trắng, viền Xám đường kẻ, bo 10, biểu tượng 18dp.

### Chips
- **Style:** chip lọc dạng viên thuốc (bo 20), đệm 8 × 14dp, chữ Label 12sp 600.
- **State:** chưa chọn là nền trắng, viền Xám đường kẻ, chữ Xám ghi chú. Đang chọn là nền Xanh hoàng gia đặc, chữ trắng, thêm dấu tích 13dp phía trước và Quầng chip chọn. Chuyển trạng thái bằng `AnimatedContainer` 180ms.

### Status Badge
- Viên nhãn bo 8, đệm 3 × 8dp, nền là màu trạng thái 10%, chữ Micro 10sp đậm cùng màu. Dùng cho trạng thái hóa đơn, kênh thông báo, vai trò.

### Cards / Containers
- **Corner Style:** bo 16dp (theme); thẻ nội dung trong màn hình đang dùng 18–20.
- **Background:** trắng trên nền giấy.
- **Shadow Strategy:** Bóng thẻ hoặc Bóng thẻ danh sách (xem Elevation & Depth).
- **Border:** 1dp Xám đường kẻ (theme) hoặc Xám sương (thẻ nội dung).
- **Internal Padding:** 16dp.
- **Tap:** `InkWell` gợn sóng bo theo góc thẻ, mở bottom sheet chi tiết.

### Icon Tile
Ô vuông 44 × 44dp bo 12, nền màu trạng thái hoặc Xanh hoàng gia 10%, biểu tượng 22dp cùng màu. Đứng đầu thẻ phòng, thẻ KPI, mục hành động cần làm. Đây là chữ ký thị giác dễ nhận nhất của app.

### Inputs / Fields
- **Style:** nền trắng, viền 1dp Xám đường kẻ, bo 14, đệm 14 × 16dp; gợi ý và nhãn 13sp Xám ghi chú.
- **Focus:** viền đổi sang Xanh hoàng gia, dày 1.5dp.
- **Search trong header:** cao 36dp, nền giấy, bo 10, biểu tượng kính lúp 16dp.

### Navigation
- **Thanh điều hướng dưới (tùy biến):** nền trắng, viền trên Xám đường kẻ và Bóng thanh điều hướng, 3–4 mục theo vai trò. Biểu tượng 20dp kiểu rounded, nhãn Micro 10sp. Mục đang chọn: biểu tượng và nhãn đậm Xanh hoàng gia trên nền viên Xanh hoàng gia 8% bo 12; chuyển trạng thái 200ms. Số đếm là viên đỏ quá hạn, chữ trắng 9sp có viền trắng.
- **Header (tùy biến):** nền trắng, viền dưới Xám đường kẻ. Nút menu, avatar chữ cái (nền Xanh hoàng gia 12%, chấm trực tuyến Xanh lá đã thu), dòng vai trò 10sp và tên 13sp đậm, nút chuông có chấm đỏ khi có thông báo chưa đọc.
- **Menu bên:** drawer tùy biến mở từ nút menu.

### Bottom Sheets & Feedback
- **Bottom sheet** là bề mặt chính cho xem chi tiết, tạo và sửa: nền trắng, mép trên bo 28. Hóa đơn chi tiết và thanh toán VietQR (mã QR động) đều là bottom sheet.
- **SnackBar** mặc định của Material cho phản hồi ngắn sau thao tác; **AlertDialog** cho xác nhận cần chặn.

## Do's and Don'ts

### Do:
- **Do** lấy màu từ token (`AppColors`) theo đúng vai trò trong mục Colors, thay vì viết lại mã hex trong từng màn hình.
- **Do** đặt nội dung trên nền Paper Slate, gói trong thẻ trắng bo 16dp với viền 1dp và bóng đổ đen tối đa 4%.
- **Do** hiện trạng thái bằng Status Badge hoặc Icon Tile: nền màu trạng thái 10%, chữ hoặc biểu tượng đậm cùng màu.
- **Do** dùng nút Confirm (Xanh lá xác nhận) cho mọi hành động chốt tiền, và nút Primary cho các hành động chính khác.
- **Do** giữ đúng bậc bo góc: 8 nhãn, 10 nút biểu tượng, 12 ô biểu tượng, 14 nút và ô nhập, 16 thẻ, 20 chip, 28 bottom sheet.
- **Do** giữ con số quan trọng (tiền, chỉ số, số phòng) đậm và dễ đọc. Người dùng chính có nhiều chủ trọ trung niên, nên cỡ 10–11sp chỉ dành cho meta phụ.

### Don't:
- **Don't** thêm banner, khối quảng cáo hay nhiều khối cùng tranh sự chú ý trên một màn hình, kiểu app quản lý miễn phí rối mắt.
- **Don't** dùng gradient rực rỡ, nhiều màu hay hiệu ứng nhấp nháy kiểu app mạng xã hội hay game. Gradient duy nhất hiện có là khối thao tác nhanh trên trang tổng quan, chuyển từ navy sang slate tối (#1E3A5F → #1E293B).
- **Don't** dùng màu chỉ để trang trí hay phân loại; mỗi màu ngoài Xanh hoàng gia phải mang nghĩa trạng thái.
- **Don't** dùng bóng đổ đậm hoặc bóng có màu cho thẻ; bóng màu chỉ cho chip đang chọn.
- **Don't** dùng Xanh lá xác nhận cho hành động không liên quan đến tiền.

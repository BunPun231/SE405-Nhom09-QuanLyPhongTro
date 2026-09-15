import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { authService, type OnboardingStatusResult } from "@/services/authService";
import { useAuthStore } from "@/store/authStore";
import { driver } from "driver.js";
import "driver.js/dist/driver.css";



export interface TourStep {
  stepNumber: number;
  title: string;
  description: string;
  targetPath: string;
  actionLabel: string;
  hint: string;
}

export const ONBOARDING_STEPS: TourStep[] = [
  {
    stepNumber: 1,
    title: "Tạo khu trọ & Cấu hình SePay",
    description: "Khai báo thông tin khu trọ đầu tiên và liên kết tài khoản ngân hàng / webhook SePay để kích hoạt tính năng tự động gạch nợ hóa đơn.",
    targetPath: "/motels",
    actionLabel: "Tới trang Khu trọ & Tạo",
    hint: "Nhấp 'Thêm khu trọ', nhập tên, địa chỉ, số tầng, cấu hình ngân hàng nhận tiền và thiết lập Webhook.",
  },
  {
    stepNumber: 2,
    title: "Tạo phòng trọ hàng loạt",
    description: "Khởi tạo nhanh danh sách các phòng trọ cụ thể trong khu trọ bằng công cụ tự động tạo hàng loạt.",
    targetPath: "/motels",
    actionLabel: "Tạo phòng hàng loạt",
    hint: "Nhấn 'Tạo hàng loạt' trên khu trọ của bác, điền số lượng phòng, diện tích và giá thuê.",
  },
  {
    stepNumber: 3,
    title: "Tạo dịch vụ không bắt buộc",
    description: "Khai báo thêm các dịch vụ bổ sung ngoài như Tiền Mạng, Tiền Rác, Xe cộ... để tính hóa đơn.",
    targetPath: "/services",
    actionLabel: "Tới trang Dịch vụ",
    hint: "Nhấn 'Thêm dịch vụ', nhập tên dịch vụ và lựa chọn loại tính phí phù hợp.",
  },
  {
    stepNumber: 4,
    title: "Tạo hợp đồng & Khách thuê",
    description: "Liên kết khách thuê vào phòng thông qua hợp đồng thuê, sử dụng AI OCR quét ảnh CCCD để điền thông tin nhanh.",
    targetPath: "/contracts",
    actionLabel: "Tới trang Hợp đồng & Tạo",
    hint: "Nhấp 'Tạo hợp đồng mới', chọn phòng, nhập giá, sử dụng ảnh CCCD mẫu để OCR rồi lưu.",
  },
  {
    stepNumber: 5,
    title: "Ghi chỉ số điện nước đầu kỳ",
    description: "Nhập chỉ số điện nước ban đầu kèm minh chứng ảnh làm căn cứ để tính toán tiêu thụ cuối tháng.",
    targetPath: "/meter",
    actionLabel: "Tới trang Điện nước & Ghi",
    hint: "Chọn phòng, sử dụng ảnh đồng hồ điện mẫu và click OCR, kiểm tra rồi lưu lại.",
  },
  {
    stepNumber: 6,
    title: "Xuất hóa đơn & Gạch nợ",
    description: "Xuất hóa đơn tháng đầu tiên, quét mã VietQR tự động để trải nghiệm gạch nợ tức thì.",
    targetPath: "/invoices",
    actionLabel: "Tới trang Hóa đơn & Lập",
    hint: "Bấm 'Tạo hóa đơn loạt', chọn khu trọ và kỳ thanh toán, sau đó xem chi tiết hóa đơn hoặc gạch nợ.",
  },
];

export const TENANT_ONBOARDING_STEPS: TourStep[] = [
  {
    stepNumber: 1,
    title: "Báo cáo chỉ số điện nước",
    description: "Nộp chỉ số điện nước phòng của bạn cuối tháng kèm ảnh chụp minh chứng để chủ trọ duyệt nhanh chóng.",
    targetPath: "/meter",
    actionLabel: "Tới trang Ghi số",
    hint: "Nhấp 'Ghi chỉ số' trên phòng của bạn, tải ảnh công tơ điện nước lên và bấm gửi.",
  },
  {
    stepNumber: 2,
    title: "Thanh toán hóa đơn phòng",
    description: "Xem và thanh toán hóa đơn phòng hàng tháng qua mã VietQR tự động gạch nợ sau 3 giây.",
    targetPath: "/invoices",
    actionLabel: "Tới trang Hóa đơn",
    hint: "Nhấp 'Mã QR' trên hóa đơn chưa thanh toán, quét mã QR qua ứng dụng ngân hàng.",
  },
];

export interface SubStep {
  id: string;
  stage: number;
  subStep: number;
  selector: string;
  title: string;
  description: string;
  targetPath: string;
  position?: "top" | "bottom" | "left" | "right";
}

export const SUB_STEPS: SubStep[] = [
  // Chặng 1: Tạo khu trọ (Target: /motels)
  {
    id: "1.1",
    stage: 1,
    subStep: 1,
    selector: "#btn-add-motel",
    title: "Thêm khu trọ mới",
    description: "Bác bấm vào đây để bắt đầu khai báo khu trọ đầu tiên nhé!",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.2",
    stage: 1,
    subStep: 2,
    selector: "#input-motel-name",
    title: "Tên khu trọ",
    description: "Bác điền tên khu trọ vào đây nhé. Ví dụ: Khu trọ Hoàng Hoa Thám",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.3",
    stage: 1,
    subStep: 3,
    selector: "#input-motel-address",
    title: "Địa chỉ khu trọ",
    description: "Bác nhập địa chỉ của khu trọ.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.4",
    stage: 1,
    subStep: 4,
    selector: "#input-motel-floors",
    title: "Số tầng",
    description: "Bác nhập tổng số tầng của khu trọ.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.5",
    stage: 1,
    subStep: 5,
    selector: "#select-closing-day",
    title: "Ngày chốt kỳ",
    description: "Bác chọn ngày chốt kỳ tính tiền hàng tháng nhé.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.6",
    stage: 1,
    subStep: 6,
    selector: "#input-deposit-ratio",
    title: "Tỷ lệ cọc",
    description: "Bác nhập tỷ lệ đặt cọc phòng mặc định (ví dụ: 100%).",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.7",
    stage: 1,
    subStep: 7,
    selector: "#select-bank-name",
    title: "Ngân hàng nhận tiền",
    description: "Bác nhấp vào đây và chọn ngân hàng bác đang sử dụng nhé. Giao diện sẽ tự động chuyển bước sau khi bác chọn.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.8",
    stage: 1,
    subStep: 8,
    selector: "#input-bank-account",
    title: "Số tài khoản",
    description: "Bác điền chính xác số tài khoản ngân hàng nhận tiền của bác vào đây.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.9",
    stage: 1,
    subStep: 9,
    selector: "#input-account-holder",
    title: "Chủ tài khoản",
    description: "Bác nhập tên chủ tài khoản (viết hoa không dấu) vào đây nhé.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.10",
    stage: 1,
    subStep: 10,
    selector: "#btn-trigger-sepay-guide-slider",
    title: "Mở ảnh hướng dẫn",
    description: "Bác bấm vào đây để mở bảng hình ảnh hướng dẫn trực quan nhé!",
    targetPath: "/motels",
    position: "top"
  },
  {
    id: "1.11",
    stage: 1,
    subStep: 11,
    selector: "#sepay-guide-step-image",
    title: "Vào quản lý Webhook",
    description: "Bước 1: Bác đăng nhập vào SePay.vn, vào mục 'Tích hợp' -> 'Webhooks' và bấm 'Thêm webhook' ở góc phải màn hình như vùng khoanh đỏ nhé.",
    targetPath: "/motels",
    position: "top"
  },
  {
    id: "1.12",
    stage: 1,
    subStep: 12,
    selector: "#btn-copy-webhook-url",
    title: "Sao chép Webhook URL",
    description: "Bây giờ hình đã ẩn, bác bấm nút Sao chép này để lấy đường dẫn mang sang dán vào SePay nhé!",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.13",
    stage: 1,
    subStep: 13,
    selector: "#sepay-guide-step-image",
    title: "Nhập đường dẫn Webhook",
    description: "Bước 2: Bác dán đường dẫn Webhook URL vừa sao chép vào ô 'URL nhận webhook' trên SePay như hình nhé.",
    targetPath: "/motels",
    position: "top"
  },
  {
    id: "1.14",
    stage: 1,
    subStep: 14,
    selector: "#sepay-guide-step-image",
    title: "Chọn tài khoản ngân hàng",
    description: "Bước 3: Bác chọn tài khoản ngân hàng nhận tiền, hoặc để mặc định là Tất cả tài khoản, rồi bấm Tiếp theo như hình nhé.",
    targetPath: "/motels",
    position: "top"
  },
  {
    id: "1.15",
    stage: 1,
    subStep: 15,
    selector: "#btn-copy-secret-key",
    title: "Sao chép Secret Key",
    description: "Bây giờ hình đã ẩn, bác sao chép tiếp Chữ ký bảo mật (Secret Key) này để dán vào ô trên SePay nhé!",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "1.16",
    stage: 1,
    subStep: 16,
    selector: "#sepay-guide-step-image",
    title: "Điền Secret Key bảo mật",
    description: "Bước 4: Bác chọn kiểu xác thực là HMAC-SHA256 và dán Secret Key vừa sao chép vào ô 'Chữ ký bảo mật (Signature Secret Key)' như hình nhé.",
    targetPath: "/motels",
    position: "top"
  },
  {
    id: "1.17",
    stage: 1,
    subStep: 17,
    selector: "#sepay-guide-step-image",
    title: "Kích hoạt Webhook",
    description: "Bước 5: Bác bấm 'Thêm' trên SePay.vn. Hãy xem hình hướng dẫn để đảm bảo webhook hiển thị trạng thái hoạt động chính xác nhé!",
    targetPath: "/motels",
    position: "top"
  },
  {
    id: "1.18",
    stage: 1,
    subStep: 18,
    selector: "#btn-submit-motel",
    title: "Lưu khu trọ & Cấu hình",
    description: "Bác bấm nút Lưu để tạo khu trọ. Hệ thống sẽ tự động gán giá Điện, Nước mặc định!",
    targetPath: "/motels",
    position: "top"
  },

  // Chặng 2: Tạo phòng trọ hàng loạt (Target: /motels)
  {
    id: "2.1",
    stage: 2,
    subStep: 1,
    selector: "#btn-bulk-create-rooms",
    title: "Tạo phòng hàng loạt",
    description: "Bác bấm vào đây để tạo nhanh nhiều phòng trọ cùng lúc!",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "2.2",
    stage: 2,
    subStep: 2,
    selector: "#input-bulk-quantity",
    title: "Số lượng phòng/tầng",
    description: "Bác nhập số lượng phòng muốn tạo trên mỗi tầng nhé.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "2.3",
    stage: 2,
    subStep: 3,
    selector: "#input-room-price",
    title: "Giá thuê mặc định",
    description: "Bác nhập giá thuê phòng mặc định vào đây.",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "2.4",
    stage: 2,
    subStep: 4,
    selector: "#input-room-area",
    title: "Diện tích mặc định",
    description: "Bác nhập diện tích phòng mặc định nhé. Đây là trường bắt buộc để hoàn tất chặng này!",
    targetPath: "/motels",
    position: "bottom"
  },
  {
    id: "2.5",
    stage: 2,
    subStep: 5,
    selector: "#btn-submit-bulk-rooms",
    title: "Hoàn tất tạo phòng",
    description: "Bác bấm nút này để hệ thống tự sinh tự động hàng loạt phòng trọ sạch sẽ!",
    targetPath: "/motels",
    position: "top"
  },

  // Chặng 3: Tạo dịch vụ không bắt buộc (Target: /services)
  {
    id: "3.1",
    stage: 3,
    subStep: 1,
    selector: "#btn-create-service",
    title: "Tạo dịch vụ ngoài",
    description: "Bác bấm vào đây để tạo thêm dịch vụ ngoài như Tiền Mạng, Tiền Rác...",
    targetPath: "/services",
    position: "bottom"
  },
  {
    id: "3.2",
    stage: 3,
    subStep: 2,
    selector: "#input-service-name",
    title: "Tên dịch vụ",
    description: "Bác nhập tên dịch vụ (hoặc chọn từ danh sách gợi ý).",
    targetPath: "/services",
    position: "bottom"
  },
  {
    id: "3.3",
    stage: 3,
    subStep: 3,
    selector: "#select-charge-type",
    title: "Loại tính phí",
    description: "Bác chọn hình thức tính phí phù hợp cho dịch vụ này nhé.",
    targetPath: "/services",
    position: "bottom"
  },
  {
    id: "3.4",
    stage: 3,
    subStep: 4,
    selector: "#input-service-price",
    title: "Đơn giá dịch vụ",
    description: "Bác nhập đơn giá cơ bản cho dịch vụ (cố định theo phòng, tính theo đầu người, hoặc đo đếm theo chỉ số đồng hồ điện/nước).",
    targetPath: "/services",
    position: "bottom"
  },
  {
    id: "3.5",
    stage: 3,
    subStep: 5,
    selector: "#checkbox-is-mandatory",
    title: "Dịch vụ bắt buộc",
    description: "Tích chọn nếu muốn dịch vụ này tự động áp dụng cho tất cả hợp đồng.",
    targetPath: "/services",
    position: "bottom"
  },
  {
    id: "3.6",
    stage: 3,
    subStep: 6,
    selector: "#btn-submit-service",
    title: "Lưu dịch vụ",
    description: "Bác bấm nút này để lưu dịch vụ vào hệ thống nhé.",
    targetPath: "/services",
    position: "top"
  },

  // Chặng 4: Tạo hợp đồng & Khách thuê (Target: /contracts)
  {
    id: "4.1",
    stage: 4,
    subStep: 1,
    selector: "#btn-create-contract",
    title: "Tạo hợp đồng mới",
    description: "Bác bấm vào đây để làm hợp đồng cho khách thuê vào ở.",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.2",
    stage: 4,
    subStep: 2,
    selector: "#select-contract-room",
    title: "Chọn phòng trống",
    description: "Bác chọn căn phòng trống vừa tạo cho khách nhé.",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.3",
    stage: 4,
    subStep: 3,
    selector: "#input-rent-price",
    title: "Tiền thuê/tháng",
    description: "Bác kiểm tra hoặc điều chỉnh giá thuê phòng thực tế tại đây nhé.",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.4",
    stage: 4,
    subStep: 4,
    selector: "#input-deposit-amount",
    title: "Tiền đặt cọc",
    description: "Bác nhập tiền đặt cọc phòng của khách nhé.",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.5",
    stage: 4,
    subStep: 5,
    selector: "#btn-use-sample-cccd",
    title: "Quét CCCD OCR",
    description: "Bác bấm vào nút Quét OCR CCCD dưới đây để hệ thống tự động nhận diện điền tên nhé!<br/><i style=\"font-size: 12px; color: #475569;\">(Để tiết kiệm thời gian tìm kiếm tệp tin, ứng dụng đã chuẩn bị sẵn một bức ảnh mẫu giúp bác làm thử cho nhanh nhé!)</i>",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.6",
    stage: 4,
    subStep: 6,
    selector: "#input-tenant-phone",
    title: "Số điện thoại khách",
    description: "Bác nhập số điện thoại của khách để hệ thống tự tạo tài khoản đăng nhập.",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.7",
    stage: 4,
    subStep: 7,
    selector: "#select-contract-services",
    title: "Đăng ký dịch vụ",
    description: "Bác tích chọn các dịch vụ sẽ sử dụng cho hợp đồng này nhé.",
    targetPath: "/contracts",
    position: "bottom"
  },
  {
    id: "4.8",
    stage: 4,
    subStep: 8,
    selector: "#btn-submit-contract",
    title: "Tạo hợp đồng",
    description: "Bác bấm nút này để tạo hợp đồng. Hệ thống sẽ tự động chuyển hướng bác sang trang danh sách khách thuê.",
    targetPath: "/contracts",
    position: "top"
  },
  {
    id: "4.9",
    stage: 4,
    subStep: 9,
    selector: "#btn-resident-detail",
    title: "Xem chi tiết khách",
    description: "Bác bấm nút Chi tiết của khách thuê vừa tạo để xem thông tin hồ sơ của họ nhé!",
    targetPath: "/residents",
    position: "bottom"
  },
  {
    id: "4.10",
    stage: 4,
    subStep: 10,
    selector: "#resident-balance-box",
    title: "Ví số dư tài khoản",
    description: "Mỗi khách thuê sẽ có một ví số dư tài khoản. Nếu đóng dư, tiền dư sẽ tự động trừ vào hóa đơn tháng sau nhé!",
    targetPath: "/residents",
    position: "top"
  },

  // Chặng 5: Ghi chỉ số đầu kỳ (Target: /meter)
  {
    id: "5.1",
    stage: 5,
    subStep: 1,
    selector: "#btn-open-meter-modal",
    title: "Ghi chỉ số",
    description: "Bác bấm vào nút Ghi chỉ số của phòng trọ để bắt đầu ghi nhận nhé!",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "5.2",
    stage: 5,
    subStep: 2,
    selector: "#btn-use-sample-meter",
    title: "Sử dụng ảnh mẫu",
    description: "Bác bấm 'Sử dụng ảnh mẫu' để tự động tải lên ảnh đồng hồ điện mẫu nhé!<br/><i style=\"font-size: 12px; color: #475569;\">(Để tiết kiệm thời gian tìm kiếm tệp tin, ứng dụng đã chuẩn bị sẵn một bức ảnh mẫu giúp bác làm thử cho nhanh nhé!)</i>",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "5.3",
    stage: 5,
    subStep: 3,
    selector: "#btn-use-sample-meter",
    title: "Nhận diện bằng AI",
    description: "Bác bấm nút Tự động nhận diện (OCR) để AI quét số trên ảnh đồng hồ nhé!",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "5.4",
    stage: 5,
    subStep: 4,
    selector: "#input-electric-index-initial",
    title: "Kiểm tra chỉ số",
    description: "Bác kiểm tra lại chỉ số điện xem đã chính xác chưa. Bác có thể điều chỉnh lại nếu cần.",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "5.5",
    stage: 5,
    subStep: 5,
    selector: "#btn-save-meter-readings",
    title: "Lưu chỉ số",
    description: "Các chỉ số này khách cũng tự nộp được. Bác bấm Lưu tất cả để hoàn tất và chuẩn bị xuất hóa đơn nhé!",
    targetPath: "/meter",
    position: "top"
  },

  // Chặng 6: Xuất hóa đơn & Gạch nợ (Target: /invoices)
  {
    id: "6.1",
    stage: 6,
    subStep: 1,
    selector: "#btn-generate-monthly-invoice",
    title: "Tạo hóa đơn loạt",
    description: "Bác bấm vào nút này để bắt đầu xuất hóa đơn hàng tháng.",
    targetPath: "/invoices",
    position: "bottom"
  },
  {
    id: "6.2",
    stage: 6,
    subStep: 2,
    selector: "#btn-submit-generate-invoice",
    title: "Tạo hóa đơn",
    description: "Chọn khu trọ, tháng và bấm nút này để hệ thống tính toán tạo hóa đơn.",
    targetPath: "/invoices",
    position: "top"
  },
  {
    id: "6.3",
    stage: 6,
    subStep: 3,
    selector: "#btn-view-generated-invoices",
    title: "Xem hóa đơn",
    description: "Bấm nút này để quay lại danh sách hóa đơn vừa tạo nhé.",
    targetPath: "/invoices",
    position: "top"
  },
  {
    id: "6.4",
    stage: 6,
    subStep: 4,
    selector: "#btn-invoice-detail",
    title: "Xem chi tiết hóa đơn",
    description: "Bác bấm Chi tiết trên dòng hóa đơn vừa tạo để xem công thức tính.",
    targetPath: "/invoices",
    position: "left"
  },
  {
    id: "6.5",
    stage: 6,
    subStep: 5,
    selector: "#btn-manual-payment",
    title: "Thu tiền thủ công",
    description: "Bấm nút này để tự gạch nợ thủ công (hoặc xem hướng dẫn VietQR thanh toán tự động).",
    targetPath: "/invoices",
    position: "top"
  }
];

export const TENANT_SUB_STEPS: SubStep[] = [
  // Chặng 1: Báo cáo chỉ số điện nước (Target: /meter)
  {
    id: "1.1",
    stage: 1,
    subStep: 1,
    selector: "#btn-open-meter-modal",
    title: "Báo cáo chỉ số",
    description: "Bác bấm vào đây để báo cáo số điện nước của phòng mình cuối tháng nhé!",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "1.2",
    stage: 1,
    subStep: 2,
    selector: "#btn-use-sample-meter",
    title: "Tải ảnh minh chứng",
    description: "Bác bấm 'Sử dụng ảnh mẫu' để tự động tải lên ảnh đồng hồ điện mẫu của phòng nhé!<br/><i style=\"font-size: 12px; color: #475569;\">(Để tiết kiệm thời gian tìm kiếm tệp tin, ứng dụng đã chuẩn bị sẵn một bức ảnh mẫu giúp bác làm thử cho nhanh nhé!)</i>",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "1.3",
    stage: 1,
    subStep: 3,
    selector: "#btn-use-sample-meter",
    title: "Nhận diện bằng AI",
    description: "Bác bấm nút Tự động nhận diện (OCR) để AI quét số trên ảnh đồng hồ điện nhé!",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "1.4",
    stage: 1,
    subStep: 4,
    selector: "#input-electric-index-initial",
    title: "Kiểm tra chỉ số điện",
    description: "Bác kiểm tra lại chỉ số điện xem đã chính xác chưa.",
    targetPath: "/meter",
    position: "bottom"
  },
  {
    id: "1.5",
    stage: 1,
    subStep: 5,
    selector: "#btn-save-meter-readings",
    title: "Gửi chỉ số",
    description: "Bác bấm nút Lưu tất cả để gửi chỉ số lên cho chủ trọ xét duyệt nhé!",
    targetPath: "/meter",
    position: "top"
  },
  // Chặng 2: Thanh toán hóa đơn (Target: /invoices)
  {
    id: "2.1",
    stage: 2,
    subStep: 1,
    selector: "#btn-preview-qr-invoice",
    title: "Xem mã QR thanh toán",
    description: "Bác bấm nút 'Mã QR' trên dòng hóa đơn chưa thanh toán của mình nhé!",
    targetPath: "/invoices",
    position: "bottom"
  },
  {
    id: "2.2",
    stage: 2,
    subStep: 2,
    selector: "#vietqr-payment-modal-content",
    title: "Quét QR thanh toán",
    description: "Mã VietQR động chứa sẵn số tiền và nội dung chuyển khoản tự động. Bác mở app ngân hàng quét mã này để hệ thống tự động gạch nợ nhé!",
    targetPath: "/invoices",
    position: "top"
  }
];

interface PageGuide {
  title: string;
  tips: string[];
}

export const PAGE_GUIDES: Record<string, PageGuide> = {
  "/dashboard": {
    title: "Trang Tổng quan",
    tips: [
      "Xem nhanh các chỉ số doanh thu dự kiến, số tiền đã thu thực tế và công nợ của tất cả khu trọ.",
      "Tỷ lệ lấp đầy hiển thị phần trăm số phòng có khách thuê thực tế trên tổng số phòng.",
      "Phần 'Cần xử lý' nhắc bác các công việc cần làm ngay như hóa đơn quá hạn hoặc chỉ số điện nước chưa duyệt."
    ]
  },
  "/motels": {
    title: "Trang Quản lý Khu trọ",
    tips: [
      "Nhấp 'Thêm khu trọ' để tạo mới một tòa nhà hoặc phân khu trọ.",
      "Nhấp 'Chi tiết' trên từng khu trọ để cấu hình phòng, quản lý các dịch vụ đi kèm riêng (như tiền rác, xe, wifi) hoặc thiết lập VietQR SePay.",
      "Để thiết lập thanh toán tự động, chọn 'Cài đặt ngân hàng' trên khu trọ và làm theo hướng dẫn sao chép URL + Secret Key."
    ]
  },
  "/services": {
    title: "Trang Cấu hình Dịch vụ",
    tips: [
      "Khai báo các dịch vụ dùng chung trong hệ thống như phí rác, gửi xe, phí quản lý, internet.",
      "Có 2 hình thức tính phí: cố định (theo phòng, theo người) và theo chỉ số tiêu thụ (như điện, nước).",
      "Khi thêm phòng trọ, các dịch vụ bắt buộc sẽ được tự động áp dụng."
    ]
  },
  "/residents": {
    title: "Trang Quản lý Khách thuê",
    tips: [
      "Danh sách tất cả khách đang thuê trọ hoặc đã chuyển đi.",
      "Bác có thể cập nhật thông tin cá nhân, số điện thoại liên lạc hoặc số CCCD/CMND của khách thuê.",
      "Khách thuê có tài khoản có thể tự đăng nhập xem hóa đơn và số dư của họ."
    ]
  },
  "/contracts": {
    title: "Trang Hợp đồng cho thuê",
    tips: [
      "Hợp đồng là căn cứ pháp lý liên kết khách thuê vào một phòng trọ cụ thể.",
      "Bác có thể thiết lập tiền đặt cọc phòng, giá thuê phòng thực tế và các điều khoản phụ lục.",
      "Hệ thống sẽ tự động cảnh báo trước 30 ngày đối với các hợp đồng chuẩn bị hết hạn để bác làm thủ tục gia hạn."
    ]
  },
  "/meter": {
    title: "Trang Chỉ số Điện nước",
    tips: [
      "Nơi nhập chỉ số điện nước (số mới) vào ngày chốt kỳ hóa đơn hàng tháng.",
      "Sau khi nhập, bác cần bấm 'Duyệt chỉ số' để hệ thống tự động lập hóa đơn tương ứng gửi cho khách thuê.",
      "Lịch sử ghi số giúp bác đối chiếu mức tiêu thụ giữa các tháng dễ dàng."
    ]
  },
  "/invoices": {
    title: "Trang Hóa đơn thu tiền",
    tips: [
      "Quản lý hóa đơn thanh toán hàng tháng của các phòng trọ.",
      "Mỗi hóa đơn đều đi kèm một mã VietQR động chứa sẵn số tiền và nội dung chuyển khoản mã hóa.",
      "Khi khách quét mã QR để chuyển tiền, SePay sẽ phát tín hiệu webhook giúp hệ thống tự động gạch nợ hóa đơn chỉ sau 3 giây!"
    ]
  },
  "/reports": {
    title: "Trang Báo cáo tài chính",
    tips: [
      "Theo dõi doanh thu thực thu, dòng tiền chênh lệch và dư nợ chưa thu hồi theo từng tháng/quý/năm.",
      "Biểu đồ trực quan giúp bác chủ trọ có cái nhìn tổng quát về hiệu quả kinh doanh của từng khu trọ.",
      "Xuất file Excel báo cáo để lưu trữ ngoại tuyến khi cần thiết."
    ]
  },
  "/settings": {
    title: "Trang Cài đặt hệ thống",
    tips: [
      "Thay đổi thông tin tài khoản cá nhân, mật khẩu đăng nhập.",
      "Quản lý thông tin Tenant (thương hiệu nhà trọ của bác) và phân quyền truy cập cho nhân viên quản lý phụ việc."
    ]
  }
};

interface TourGuideContextType {
  onboardingStatus: OnboardingStatusResult | null;
  loading: boolean;
  currentStep: number;
  activeStepData: TourStep | null;
  hasCompletedOnboarding: boolean;
  refreshStatus: () => Promise<void>;
  completeOnboarding: () => Promise<void>;
  isGuideOpen: boolean;
  setIsGuideOpen: (open: boolean) => void;
  showCelebration: boolean;
  setShowCelebration: (show: boolean) => void;
  pageGuide: PageGuide | null;
  activeSubStepId: string;
  setActiveSubStepId: (id: string) => void;
  isDriverActive: boolean;
  localOverrideStep: number | null;
  setLocalOverrideStep: (step: number | null) => void;
  advanceTenantStep: () => void;
  completeTenantOnboarding: () => void;
  advanceSubStep: () => void;
  regressSubStep: () => void;
}

const TourGuideContext = createContext<TourGuideContextType | undefined>(undefined);

export function TourGuideProvider({ children }: { children: React.ReactNode }) {
  const { user, setUser } = useAuthStore();
  const location = useLocation();
  const navigate = useNavigate();

  const [onboardingStatus, setOnboardingStatus] = useState<OnboardingStatusResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [currentStep, setCurrentStep] = useState<number>(1);
  const [activeStepData, setActiveStepData] = useState<TourStep | null>(null);
  const [isGuideOpen, setIsGuideOpen] = useState(false);
  const [showCelebration, setShowCelebration] = useState(false);
  const [isDriverActive, setIsDriverActive] = useState(false);
  const [localOverrideStep, setLocalOverrideStep] = useState<number | null>(null);
  const [activeSubStepId, setActiveSubStepId] = useState<string>(() => {
    return localStorage.getItem("onboarding_substep") || "1.1";
  });

  // Tenant states
  const [tenantStep, setTenantStep] = useState<number>(() => {
    return parseInt(localStorage.getItem("tenant_onboarding_step") || "1", 10);
  });
  const [tenantSubStepId, setTenantSubStepId] = useState<string>(() => {
    return localStorage.getItem("tenant_onboarding_substep") || "1.1";
  });
  const [tenantCompleted, setTenantCompleted] = useState<boolean>(() => {
    return localStorage.getItem("tenant_onboarding_completed") === "true";
  });

  const isTenantMode = !!(user && ((user.role as string) === "TENANT" || (user.role as string) === "RESIDENT"));
  const isEligible = !!(user && ((user.role as string) === "MANAGER" || (user.role as string) === "ADMIN" || (user.role as string) === "TENANT" || (user.role as string) === "RESIDENT"));

  const effectiveStep = isTenantMode ? tenantStep : (localOverrideStep !== null ? localOverrideStep : currentStep);
  const effectiveSubStepId = isTenantMode ? tenantSubStepId : activeSubStepId;
  const effectiveStepsList = isTenantMode ? TENANT_ONBOARDING_STEPS : ONBOARDING_STEPS;
  const effectiveSubStepsList = isTenantMode ? TENANT_SUB_STEPS : SUB_STEPS;
  const hasCompletedOnboarding = isTenantMode ? tenantCompleted : (onboardingStatus?.hasCompletedOnboarding ?? user?.hasCompletedOnboarding ?? false);

  // Clear override when step advances
  useEffect(() => {
    setLocalOverrideStep(null);
  }, [currentStep]);

  useEffect(() => {
    if (effectiveStep >= 1 && effectiveStep <= effectiveStepsList.length) {
      setActiveStepData(effectiveStepsList[effectiveStep - 1]);
    } else {
      setActiveStepData(null);
    }
  }, [effectiveStep, isTenantMode]);

  const driverInstanceRef = useRef<any>(null);
  const isTransitioningRef = useRef(false);
  const activeSubStepIdRef = useRef(effectiveSubStepId);
  const activeStepRef = useRef<any>(null);

  useEffect(() => {
    activeSubStepIdRef.current = effectiveSubStepId;
    activeStepRef.current = effectiveSubStepsList.find(s => s.id === effectiveSubStepId);
  }, [effectiveSubStepId, effectiveSubStepsList]);

  const refreshStatus = useCallback(async () => {
    if (!isEligible || isTenantMode) return;
    setLoading(true);
    try {
      const status = await authService.getOnboardingStatus();
      setOnboardingStatus(status);
      const step = status.currentStep || 1;
      setCurrentStep(step);

      if (status.hasInvoice && !status.hasCompletedOnboarding) {
        setShowCelebration(true);
      }

      if (status.hasCompletedOnboarding !== user.hasCompletedOnboarding) {
        setUser({
          ...user,
          hasCompletedOnboarding: status.hasCompletedOnboarding,
        });
      }
    } catch (err) {
      console.error("Failed to load onboarding status", err);
    } finally {
      setLoading(false);
    }
  }, [isEligible, isTenantMode, user, setUser]);

  const completeOnboarding = async () => {
    if (!isEligible || isTenantMode) return;
    try {
      await authService.completeOnboarding();
      if (user) {
        setUser({
          ...user,
          hasCompletedOnboarding: true,
        });
      }
      if (onboardingStatus) {
        setOnboardingStatus({
          ...onboardingStatus,
          hasCompletedOnboarding: true,
        });
      }
      setCurrentStep(7);
      setActiveStepData(null);
      setShowCelebration(true);
    } catch (err) {
      console.error("Failed to complete onboarding", err);
    }
  };

  const advanceTenantStep = useCallback(() => {
    const nextStep = tenantStep + 1;
    if (nextStep <= 2) {
      setTenantStep(nextStep);
      localStorage.setItem("tenant_onboarding_step", nextStep.toString());
      const firstSubStep = TENANT_SUB_STEPS.find(s => s.stage === nextStep);
      if (firstSubStep) {
        setTenantSubStepId(firstSubStep.id);
        localStorage.setItem("tenant_onboarding_substep", firstSubStep.id);
      }
    } else {
      setTenantCompleted(true);
      localStorage.setItem("tenant_onboarding_completed", "true");
      setIsGuideOpen(false);
    }
  }, [tenantStep]);

  const completeTenantOnboarding = useCallback(() => {
    setTenantCompleted(true);
    localStorage.setItem("tenant_onboarding_completed", "true");
    setIsGuideOpen(false);
  }, []);

  // Sync sub-step to the current stage
  useEffect(() => {
    if (!isTenantMode && effectiveStep >= 1 && effectiveStep <= 6) {
      const expectedPrefix = `${effectiveStep}.`;
      if (!activeSubStepId.startsWith(expectedPrefix)) {
        const firstSubStep = SUB_STEPS.find(s => s.stage === effectiveStep);
        if (firstSubStep) {
          setActiveSubStepId(firstSubStep.id);
          localStorage.setItem("onboarding_substep", firstSubStep.id);
        }
      }
    } else if (isTenantMode && effectiveStep >= 1 && effectiveStep <= 2) {
      const expectedPrefix = `${effectiveStep}.`;
      if (!tenantSubStepId.startsWith(expectedPrefix)) {
        const firstSubStep = TENANT_SUB_STEPS.find(s => s.stage === effectiveStep);
        if (firstSubStep) {
          setTenantSubStepId(firstSubStep.id);
          localStorage.setItem("tenant_onboarding_substep", firstSubStep.id);
        }
      }
    }
  }, [effectiveStep, activeSubStepId, tenantSubStepId, isTenantMode]);

  const advanceSubStep = useCallback(() => {
    if (isTenantMode) {
      const currentIndex = TENANT_SUB_STEPS.findIndex(s => s.id === tenantSubStepId);
      if (currentIndex !== -1 && currentIndex < TENANT_SUB_STEPS.length - 1) {
        const nextStep = TENANT_SUB_STEPS[currentIndex + 1];
        if (nextStep.stage === tenantStep || nextStep.stage === tenantStep + 1) {
          setTenantSubStepId(nextStep.id);
          localStorage.setItem("tenant_onboarding_substep", nextStep.id);
          if (nextStep.stage === tenantStep + 1) {
            const nextTenantStep = tenantStep + 1;
            setTenantStep(nextTenantStep);
            localStorage.setItem("tenant_onboarding_step", nextTenantStep.toString());
            navigate(nextStep.targetPath);
          }
        }
      }
    } else {
      const currentIndex = SUB_STEPS.findIndex(s => s.id === activeSubStepId);
      if (currentIndex !== -1 && currentIndex < SUB_STEPS.length - 1) {
        const nextStep = SUB_STEPS[currentIndex + 1];
        if (nextStep.stage === effectiveStep || nextStep.stage === effectiveStep + 1) {
          // Instantly close/open image modal for smooth transitions
          const openSteps = ["1.11", "1.13", "1.14", "1.16", "1.17"];
          const wasOpen = openSteps.includes(activeSubStepId);
          const shouldBeOpen = openSteps.includes(nextStep.id);

          if (wasOpen && !shouldBeOpen) {
            const closeGuideBtn = document.querySelector('#btn-close-sepay-image-modal') as HTMLButtonElement;
            if (closeGuideBtn) closeGuideBtn.click();
          } else if (!wasOpen && shouldBeOpen) {
            // Expand and open fullscreen image modal immediately
            setTimeout(() => {
              const openGuideBtn = document.querySelector("#btn-open-sepay-image-modal") as HTMLButtonElement;
              if (openGuideBtn) {
                openGuideBtn.click();
              } else {
                const expandBtn = document.querySelector("#btn-trigger-sepay-guide-slider") as HTMLButtonElement;
                if (expandBtn) {
                  expandBtn.click();
                  setTimeout(() => {
                    const openBtn = document.querySelector("#btn-open-sepay-image-modal") as HTMLButtonElement;
                    if (openBtn) openBtn.click();
                  }, 55);
                }
              }
            }, 55);
          }
          setActiveSubStepId(nextStep.id);
          localStorage.setItem("onboarding_substep", nextStep.id);
          if (nextStep.stage === effectiveStep + 1) {
            navigate(nextStep.targetPath);
          }
        }
      }
    }
  }, [isTenantMode, tenantSubStepId, tenantStep, activeSubStepId, effectiveStep, navigate]);

  const regressSubStep = useCallback(() => {
    if (isTenantMode) {
      const currentIndex = TENANT_SUB_STEPS.findIndex(s => s.id === tenantSubStepId);
      if (currentIndex > 0) {
        const prevStep = TENANT_SUB_STEPS[currentIndex - 1];
        if (prevStep.stage === tenantStep) {
          setTenantSubStepId(prevStep.id);
          localStorage.setItem("tenant_onboarding_substep", prevStep.id);
        }
      }
    } else {
      const currentIndex = SUB_STEPS.findIndex(s => s.id === activeSubStepId);
      if (currentIndex > 0) {
        const prevStep = SUB_STEPS[currentIndex - 1];
        if (prevStep.stage === effectiveStep) {
          // Instantly close/open image modal for smooth transitions
          const openSteps = ["1.11", "1.13", "1.14", "1.16", "1.17"];
          const wasOpen = openSteps.includes(activeSubStepId);
          const shouldBeOpen = openSteps.includes(prevStep.id);

          if (wasOpen && !shouldBeOpen) {
            const closeGuideBtn = document.querySelector('#btn-close-sepay-image-modal') as HTMLButtonElement;
            if (closeGuideBtn) closeGuideBtn.click();
          } else if (!wasOpen && shouldBeOpen) {
            // Expand and open fullscreen image modal immediately
            setTimeout(() => {
              const openGuideBtn = document.querySelector("#btn-open-sepay-image-modal") as HTMLButtonElement;
              if (openGuideBtn) {
                openGuideBtn.click();
              } else {
                const expandBtn = document.querySelector("#btn-trigger-sepay-guide-slider") as HTMLButtonElement;
                if (expandBtn) {
                  expandBtn.click();
                  setTimeout(() => {
                    const openBtn = document.querySelector("#btn-open-sepay-image-modal") as HTMLButtonElement;
                    if (openBtn) openBtn.click();
                  }, 55);
                }
              }
            }, 55);
          }
          setActiveSubStepId(prevStep.id);
          localStorage.setItem("onboarding_substep", prevStep.id);
        }
      }
    }
  }, [isTenantMode, tenantSubStepId, tenantStep, activeSubStepId, effectiveStep]);

  // Bind the 'Enter' key globally when the tour guide is active (only for text inputs)
  useEffect(() => {
    if (!isGuideOpen || !isDriverActive) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Enter") {
        const activeEl = document.activeElement;
        if (activeEl && activeEl.tagName === "INPUT") {
          const inputEl = activeEl as HTMLInputElement;
          const isText = ["text", "number", "tel", "email", "password"].includes(inputEl.type || "text") &&
            inputEl.getAttribute("role") !== "combobox";

          if (isText) {
            e.preventDefault();
            advanceSubStep();
          }
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown, true);
    return () => {
      window.removeEventListener("keydown", handleKeyDown, true);
    };
  }, [isGuideOpen, isDriverActive, advanceSubStep]);

  // Main active driver.js loop
  useEffect(() => {
    if (hasCompletedOnboarding || !isGuideOpen || effectiveStep < 1 || effectiveStep > effectiveStepsList.length) {
      if (driverInstanceRef.current) {
        isTransitioningRef.current = true;
        driverInstanceRef.current.destroy();
        driverInstanceRef.current = null;
        isTransitioningRef.current = false;
      }
      return;
    }

    const interval = setInterval(() => {
      const activeStep = effectiveSubStepsList.find(s => s.id === effectiveSubStepId);
      if (!activeStep) return;

      // Programmatic image modal toggling for SePay steps
      if (!isTenantMode) {
        const openSteps = ["1.11", "1.13", "1.14", "1.16", "1.17"];
        if (openSteps.includes(effectiveSubStepId)) {
          // We need the fullscreen image modal to be OPEN
          const isFullscreenOpen = !!document.querySelector("#btn-close-sepay-image-modal");
          if (!isFullscreenOpen) {
            // Check if the guide panel is expanded
            const openGuideBtn = document.querySelector("#btn-open-sepay-image-modal") as HTMLButtonElement;
            if (openGuideBtn) {
              openGuideBtn.click();
            } else {
              // Expand the guide panel first
              const expandBtn = document.querySelector("#btn-trigger-sepay-guide-slider") as HTMLButtonElement;
              if (expandBtn) {
                expandBtn.click();
              }
            }
            return;
          }
        } else {
          // For all other steps, make sure the fullscreen image modal is CLOSED
          const closeGuideBtn = document.querySelector("#btn-close-sepay-image-modal") as HTMLButtonElement;
          if (closeGuideBtn) {
            closeGuideBtn.click();
            return;
          }
        }
      }

      // 1. Auto-advance transitions based on visibility of elements belonging to next step
      if (!isTenantMode) {
        if (effectiveSubStepId === "1.1" && document.querySelector("#input-motel-name")) {
          setActiveSubStepId("1.2");
          localStorage.setItem("onboarding_substep", "1.2");
          return;
        }
        if (effectiveSubStepId === "2.1" && document.querySelector("#input-bulk-quantity")) {
          setActiveSubStepId("2.2");
          localStorage.setItem("onboarding_substep", "2.2");
          return;
        }
        if (effectiveSubStepId === "3.1" && document.querySelector("#input-service-name")) {
          setActiveSubStepId("3.2");
          localStorage.setItem("onboarding_substep", "3.2");
          return;
        }
        if (effectiveSubStepId === "4.1" && document.querySelector("#select-contract-room")) {
          setActiveSubStepId("4.2");
          localStorage.setItem("onboarding_substep", "4.2");
          return;
        }
        if (effectiveSubStepId === "4.8" && location.pathname === "/residents" && document.querySelector("#btn-resident-detail")) {
          setActiveSubStepId("4.9");
          localStorage.setItem("onboarding_substep", "4.9");
          return;
        }
        if (effectiveSubStepId === "4.9" && document.querySelector("#resident-balance-box")) {
          setActiveSubStepId("4.10");
          localStorage.setItem("onboarding_substep", "4.10");
          return;
        }
        if (effectiveSubStepId === "5.1" && document.querySelector("#btn-use-sample-meter")) {
          setActiveSubStepId("5.2");
          localStorage.setItem("onboarding_substep", "5.2");
          return;
        }
        if (effectiveSubStepId === "6.1" && document.querySelector("#invoice-generate-motel")) {
          setActiveSubStepId("6.2");
          localStorage.setItem("onboarding_substep", "6.2");
          return;
        }
        if (effectiveSubStepId === "6.2" && document.querySelector("#btn-view-generated-invoices")) {
          setActiveSubStepId("6.3");
          localStorage.setItem("onboarding_substep", "6.3");
          return;
        }
      } else {
        // Tenant Mode
        if (tenantSubStepId === "1.1" && document.querySelector("#btn-use-sample-meter")) {
          setTenantSubStepId("1.2");
          localStorage.setItem("tenant_onboarding_substep", "1.2");
          return;
        }
        if (tenantSubStepId === "2.1" && document.querySelector("#vietqr-payment-modal-content")) {
          setTenantSubStepId("2.2");
          localStorage.setItem("tenant_onboarding_substep", "2.2");
          return;
        }
      }

      // 2. Auto-routing: if user is on the wrong route, navigate or wait
      const isWrongRoute = location.pathname !== activeStep.targetPath;
      if (isWrongRoute) {
        if (driverInstanceRef.current) {
          isTransitioningRef.current = true;
          driverInstanceRef.current.destroy();
          driverInstanceRef.current = null;
          isTransitioningRef.current = false;
        }
        return;
      }

      // 3. Find target element
      const targetElement = document.querySelector(activeStep.selector);
      if (!targetElement) {
        if (driverInstanceRef.current) {
          isTransitioningRef.current = true;
          driverInstanceRef.current.destroy();
          driverInstanceRef.current = null;
          isTransitioningRef.current = false;
        }
        return;
      }

      // Check if target is actually visible
      const rect = targetElement.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) {
        if (driverInstanceRef.current) {
          isTransitioningRef.current = true;
          driverInstanceRef.current.destroy();
          driverInstanceRef.current = null;
          isTransitioningRef.current = false;
        }
        return;
      }

      // Check if driver is already highlighting this element
      const isAlreadyHighlighting = driverInstanceRef.current &&
        driverInstanceRef.current.isActive() &&
        driverInstanceRef.current.getActiveElement() === targetElement;

      if (isAlreadyHighlighting) {
        return;
      }

      const nextBtnLabel = "Tiếp tục ➜";

      // If driver is already active, we just call highlight smoothly to glide spotlight
      if (driverInstanceRef.current && driverInstanceRef.current.isActive()) {
        driverInstanceRef.current.highlight({
          element: activeStep.selector,
          popover: {
            title: `Chặng ${effectiveStep}.${activeStep.subStep}: ${activeStep.title}`,
            description: activeStep.description,
            side: activeStep.position || "bottom",
            align: "start",
            nextBtnText: nextBtnLabel,
            prevBtnText: "← Quay lại"
          }
        });

        // Automatically focus highlighted element
        setTimeout(() => {
          const el = document.querySelector(activeStep.selector) as HTMLElement;
          if (el && (el.tagName === "INPUT" || el.tagName === "SELECT" || el.tagName === "TEXTAREA")) {
            el.focus();
            if (el instanceof HTMLInputElement) {
              el.select();
            }
          }
        }, 100);

        return;
      }

      // Recreate or launch driver.js
      if (driverInstanceRef.current) {
        isTransitioningRef.current = true;
        driverInstanceRef.current.destroy();
        isTransitioningRef.current = false;
      }

      const stageSteps = effectiveSubStepsList.filter(s => s.stage === effectiveStep);
      const activeIndex = stageSteps.findIndex(s => s.id === effectiveSubStepId);
      const isFirst = activeIndex === 0;

      const buttons: ("next" | "previous")[] = [];
      if (!isFirst) buttons.push("previous");
      buttons.push("next");

      const d = driver({
        allowClose: false,
        overlayColor: "rgba(15, 23, 42, 0.7)",
        stagePadding: 6,
        stageRadius: 12,
        showProgress: false,
        showButtons: buttons,
        popoverClass: "driverjs-theme-custom font-sans",
        onHighlighted: (element?: Element) => {
          // Wait slightly for the DOM string to append completely inside the container
          setTimeout(() => {
            const dismissLink = document.querySelector("#btn-tour-dismiss-trigger");
            if (dismissLink) {
              dismissLink.addEventListener("click", (e) => {
                e.preventDefault();
                e.stopPropagation();

                // Natively kill the active tour overlay completely
                if (driverInstanceRef.current) {
                  driverInstanceRef.current.destroy();
                } else {
                  d.destroy();
                }
              });
            }
          }, 50);
        },
        onPopoverRender: (popover) => {
          const currentStep = activeStepRef.current;
          const currentStepId = activeSubStepIdRef.current;
          if (!currentStep) return;

          const targetEl = document.querySelector(currentStep.selector);

          // Card wrapper styling - Apply to ALL steps!
          popover.wrapper.style.padding = "24px";
          popover.wrapper.style.borderRadius = "16px";
          popover.wrapper.style.border = "2px solid #2563eb";
          popover.wrapper.style.backgroundColor = "#ffffff";
          popover.wrapper.style.boxShadow = "0 20px 25px -5px rgb(0 0 0 / 0.15), 0 8px 10px -6px rgb(0 0 0 / 0.15)";
          popover.wrapper.style.maxWidth = "360px";

          // Title styling
          popover.title.style.fontSize = "16px";
          popover.title.style.fontWeight = "800";
          popover.title.style.color = "#1e293b";
          popover.title.style.marginBottom = "10px";
          popover.title.style.fontFamily = "inherit";
          popover.title.style.marginRight = "0";

          // Build description HTML
          const isTextInput = targetEl && targetEl.tagName === "INPUT" && (
            !(targetEl as HTMLInputElement).type ||
            ["text", "number", "tel", "email", "password"].includes((targetEl as HTMLInputElement).type)
          ) && targetEl.getAttribute("role") !== "combobox";

          let descriptionHtml = `
            <div style="font-size: 14px; color: #374151; line-height: 1.5; font-family: inherit;">
              ${currentStep.description}
            </div>
          `;

          if (currentStepId === "1.10") {
            descriptionHtml += `
              <br/>
              <a href="https://sepay.vn" target="_blank" rel="noopener noreferrer" style="color: #2563eb; font-weight: bold; text-decoration: underline; display: inline-flex; align-items: center; gap: 4px; font-family: inherit; font-size: 13px;">
                [Bấm vào đây để mở trang SePay.vn] ↗
              </a>
            `;
          }

          // Show input guide tip ONLY on text inputs (exclude dropdowns/comboboxes)
          if (isTextInput) {
            descriptionHtml += `
              <p style="font-size: 12px; color: #64748b; font-style: italic; margin: 12px 0 0 0; font-family: inherit;">
                *(Bác có thể gõ xong rồi ấn phím Enter trên bàn phím cho nhanh nhé)*
              </p>
            `;
          }

          descriptionHtml += `
            <div style="margin-top: 16px; padding-top: 8px; border-top: 1px dashed #e5e7eb; display: flex; justify-content: flex-start; width: 100%; font-family: inherit;">
              <span id="btn-tour-dismiss-trigger" style="color: #9ca3af; text-decoration: underline; cursor: pointer; font-size: 12px; font-weight: 500; white-space: nowrap;">Bỏ qua hướng dẫn</span>
            </div>
          `;

          popover.description.innerHTML = descriptionHtml;
          popover.description.style.fontFamily = "inherit";

          // Bind dismiss trigger click action synchronously inside onPopoverRender
          const dismissLink = popover.description.querySelector("#btn-tour-dismiss-trigger");
          if (dismissLink) {
            dismissLink.addEventListener("click", (e) => {
              e.preventDefault();
              e.stopPropagation();
              if (driverInstanceRef.current) {
                driverInstanceRef.current.destroy();
              } else {
                d.destroy();
              }
            });
          }

          // Enforce footer container styling
          popover.footer.style.display = "flex";
          popover.footer.style.justifyContent = "flex-end";
          popover.footer.style.alignItems = "center";
          popover.footer.style.gap = "8px";
          popover.footer.style.marginTop = "20px";

          // Next Button Setup
          popover.nextButton.id = "btn-tour-next-trigger";
          popover.nextButton.className = "driver-popover-next-btn tour-pulse-button";
          popover.nextButton.innerHTML = "Tiếp tục ➜";

          // Style next button - center text with flex, fix baseline-crush
          popover.nextButton.style.display = "flex";
          popover.nextButton.style.alignItems = "center";
          popover.nextButton.style.justifyContent = "center";
          popover.nextButton.style.lineHeight = "1";
          popover.nextButton.style.height = "auto";
          popover.nextButton.style.padding = "0px 20px";
          popover.nextButton.style.fontSize = "14px";
          popover.nextButton.style.fontWeight = "normal";
          popover.nextButton.style.borderRadius = "8px";
          popover.nextButton.style.backgroundColor = "#2563eb"; // Solid primary blue
          popover.nextButton.style.color = "#ffffff";
          popover.nextButton.style.border = "none";
          popover.nextButton.style.cursor = "pointer";
          popover.nextButton.style.boxShadow = "0 4px 6px -1px rgb(37 99 235 / 0.2)";
          popover.nextButton.style.fontFamily = "inherit";

          // Hide next button on submit steps to enforce clicking the real button in UI
          const isSubmitStep = (
            currentStepId === "1.18" ||
            currentStepId === "2.5" ||
            currentStepId === "3.6" ||
            currentStepId === "4.8" ||
            currentStepId === "5.5" ||
            currentStepId === "6.2"
          );
          if (isSubmitStep) {
            popover.nextButton.style.display = "none";
          }

          // Previous Button Setup
          const subStepsList = isTenantMode ? TENANT_SUB_STEPS : SUB_STEPS;
          const stageSteps = subStepsList.filter(s => s.stage === currentStep.stage);
          const activeIndex = stageSteps.findIndex(s => s.id === currentStepId);
          const isCurrFirst = activeIndex === 0;

          popover.previousButton.style.display = isCurrFirst ? "none" : "flex";
          popover.previousButton.style.alignItems = "center";
          popover.previousButton.style.justifyContent = "center";
          popover.previousButton.style.lineHeight = "1";
          popover.previousButton.style.height = "auto";
          popover.previousButton.style.padding = "10px 16px";
          popover.previousButton.style.fontSize = "13px";
          popover.previousButton.style.fontWeight = "600";
          popover.previousButton.style.borderRadius = "8px";
          popover.previousButton.style.border = "1px solid #cbd5e1"; // Neutral dark border
          popover.previousButton.style.backgroundColor = "#ffffff";
          popover.previousButton.style.color = "#475569";
          popover.previousButton.style.cursor = "pointer";
          popover.previousButton.style.fontFamily = "inherit";
        },
        onNextClick: () => {
          advanceSubStep();
        },
        onPrevClick: () => {
          regressSubStep();
        },
        onDestroyed: () => {
          setIsDriverActive(false);
          if (!isTransitioningRef.current) {
            setIsGuideOpen(false);
          }
        }
      });

      driverInstanceRef.current = d;
      setIsDriverActive(true);

      d.highlight({
        element: activeStep.selector,
        popover: {
          title: `Chặng ${effectiveStep}.${activeStep.subStep}: ${activeStep.title}`,
          description: activeStep.description,
          side: activeStep.position || "bottom",
          align: "start",
          nextBtnText: nextBtnLabel,
          prevBtnText: "← Quay lại"
        }
      });

      // Automatically focus highlighted element
      setTimeout(() => {
        const el = document.querySelector(activeStep.selector) as HTMLElement;
        if (el && (el.tagName === "INPUT" || el.tagName === "SELECT" || el.tagName === "TEXTAREA")) {
          el.focus();
          if (el instanceof HTMLInputElement) {
            el.select();
          }
        }
      }, 100);
    }, 400);

    return () => {
      clearInterval(interval);
      if (driverInstanceRef.current) {
        isTransitioningRef.current = true;
        driverInstanceRef.current.destroy();
        driverInstanceRef.current = null;
        isTransitioningRef.current = false;
      }
      setIsDriverActive(false);
    };
  }, [hasCompletedOnboarding, isGuideOpen, effectiveStep, effectiveSubStepId, location.pathname, advanceSubStep, regressSubStep, isTenantMode]);

  useEffect(() => {
    if (isEligible && !isTenantMode) {
      refreshStatus();
    }
  }, [location.pathname]);

  const pageGuide = PAGE_GUIDES[location.pathname] || null;

  return (
    <TourGuideContext.Provider
      value={{
        onboardingStatus,
        loading,
        currentStep: effectiveStep,
        activeStepData,
        hasCompletedOnboarding,
        refreshStatus,
        completeOnboarding,
        isGuideOpen,
        setIsGuideOpen,
        showCelebration,
        setShowCelebration,
        pageGuide,
        activeSubStepId: effectiveSubStepId,
        setActiveSubStepId: isTenantMode ? setTenantSubStepId : setActiveSubStepId,
        isDriverActive,
        localOverrideStep,
        setLocalOverrideStep,
        advanceTenantStep,
        completeTenantOnboarding,
        advanceSubStep,
        regressSubStep
      }}
    >
      {children}
    </TourGuideContext.Provider>
  );
}

export function useTourGuide() {
  const context = useContext(TourGuideContext);
  if (context === undefined) {
    throw new Error("useTourGuide must be used within a TourGuideProvider");
  }
  return context;
}

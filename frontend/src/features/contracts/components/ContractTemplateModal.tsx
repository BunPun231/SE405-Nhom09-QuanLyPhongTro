import { useState, useEffect } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { motelService, roomService, type MotelResult, type RoomResult } from "@/services/motelService";
import { residentService, type ResidentResult } from "@/services/residentService";
import type { ContractResult } from "@/services/contractService";
import { extractError } from "@/lib/api";

interface ContractTemplateModalProps {
  isOpen: boolean;
  onClose: () => void;
  contract: ContractResult;
}

const DEFAULT_TEMPLATE = `CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
Độc lập - Tự do - Hạnh phúc
-----

HỢP ĐỒNG THUÊ PHÒNG TRỌ

Hôm nay, ngày {{TODAY}}, chúng tôi gồm:

BÊN CHO THUÊ (BÊN A):
- Đại diện khu trọ: {{MOTEL_NAME}}
- Địa chỉ: {{MOTEL_ADDRESS}}

BÊN THUÊ (BÊN B):
- Họ và tên: {{TENANT_NAME}}
- Số CCCD/CMND: {{TENANT_CCCD}}
- Điện thoại: {{TENANT_PHONE}}

Hai bên đồng ý ký kết hợp đồng thuê phòng trọ với các điều khoản sau:

Điều 1: Nội dung hợp đồng
- Bên A đồng ý cho Bên B thuê phòng số {{ROOM_NUMBER}} thuộc khu trọ {{MOTEL_NAME}}.
- Thời hạn thuê: Từ ngày {{START_DATE}} đến ngày {{END_DATE}}.

Điều 2: Giá cả và phương thức thanh toán
- Giá thuê phòng: {{RENT_PRICE}} đ/tháng.
- Tiền đặt cọc: {{DEPOSIT_AMOUNT}} đ.
- Ngày chốt tiền phòng hàng tháng: {{BILLING_DATE}}.

Điều 3: Cam kết chung
- Bên B cam kết tuân thủ nội quy khu trọ, giữ gìn an ninh trật tự, vệ sinh chung.
- Bên A cam kết cung cấp điện, nước đầy đủ theo định mức thỏa thuận.

Đại diện Bên A                                    Đại diện Bên B
(Ký, ghi rõ họ tên)                               (Ký, ghi rõ họ tên)
`;

export function ContractTemplateModal({ isOpen, onClose, contract }: ContractTemplateModalProps) {
  const [templateText, setTemplateText] = useState("");
  const [motel, setMotel] = useState<MotelResult | null>(null);
  const [room, setRoom] = useState<RoomResult | null>(null);
  const [resident, setResident] = useState<ResidentResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    const saved = localStorage.getItem("contract_print_template");
    if (saved) {
      setTemplateText(saved);
    } else {
      setTemplateText(DEFAULT_TEMPLATE);
    }
  }, [isOpen]);

  useEffect(() => {
    if (isOpen && contract) {
      setLoading(true);
      setError("");
      
      const loadDetails = async () => {
        try {
          // 1. Fetch all motels to find which one contains the contract's room
          const motelList = await motelService.list(0, 100);
          let foundRoom: RoomResult | null = null;
          let foundMotel: MotelResult | null = null;

          for (const m of motelList.content) {
            const roomsRes = await roomService.list(m.id);
            const r = roomsRes.content.find(room => room.id === contract.roomId);
            if (r) {
              foundRoom = r;
              foundMotel = m;
              break;
            }
          }

          if (foundRoom && foundMotel) {
            setRoom(foundRoom);
            setMotel(foundMotel);
          }

          // 2. Fetch resident
          if (contract.primaryResidentUserId) {
            const resObj = await residentService.get(contract.primaryResidentUserId);
            setResident(resObj);
          }
        } catch (err) {
          console.error("Error loading print details", err);
          setError("Không thể tải đầy đủ thông tin in hợp đồng. Vui lòng nhập tay bổ sung.");
        } finally {
          setLoading(false);
        }
      };

      loadDetails();
    }
  }, [isOpen, contract]);

  const handleSaveTemplate = () => {
    localStorage.setItem("contract_print_template", templateText);
    alert("Đã lưu mẫu thiết kế hợp đồng!");
  };

  const handleResetTemplate = () => {
    if (confirm("Bạn có chắc chắn muốn đặt lại mẫu mặc định?")) {
      setTemplateText(DEFAULT_TEMPLATE);
      localStorage.removeItem("contract_print_template");
    }
  };

  const handlePrint = () => {
    let content = templateText;
    const formatDate = (dateStr?: string) => {
      if (!dateStr) return "";
      try {
        const d = new Date(dateStr);
        return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
      } catch {
        return dateStr;
      }
    };

    const replacements: Record<string, string> = {
      "{{TODAY}}": new Date().toLocaleDateString("vi-VN"),
      "{{MOTEL_NAME}}": motel?.name || "(Chưa có tên khu trọ)",
      "{{MOTEL_ADDRESS}}": motel?.address || "(Chưa có địa chỉ)",
      "{{TENANT_NAME}}": resident?.fullName || "(Chưa có tên khách)",
      "{{TENANT_CCCD}}": resident?.idCardNumber || "(Chưa có số CCCD)",
      "{{TENANT_PHONE}}": resident?.phone || "(Chưa có SĐT)",
      "{{ROOM_NUMBER}}": room ? `${room.roomNumber}` : "(Chưa có số phòng)",
      "{{RENT_PRICE}}": contract.rentPrice.toLocaleString("vi-VN"),
      "{{DEPOSIT_AMOUNT}}": contract.depositAmount.toLocaleString("vi-VN"),
      "{{BILLING_DATE}}": contract.billingDate ? formatDate(contract.billingDate) : "(Chưa chốt)",
      "{{START_DATE}}": formatDate(contract.startDate),
      "{{END_DATE}}": formatDate(contract.endDate),
    };

    Object.entries(replacements).forEach(([key, val]) => {
      content = content.replaceAll(key, val);
    });

    const printWindow = window.open("", "_blank");
    if (printWindow) {
      printWindow.document.write(`
        <html>
          <head>
            <title>In Hợp Đồng - ${resident?.fullName || ""}</title>
            <style>
              body {
                font-family: "Times New Roman", Times, serif;
                font-size: 13pt;
                line-height: 1.6;
                padding: 25mm 20mm 20mm 20mm;
                margin: 0;
                color: #000;
              }
              pre {
                white-space: pre-wrap;
                word-wrap: break-word;
                font-family: inherit;
              }
              @media print {
                body {
                  padding: 0;
                }
              }
            </style>
          </head>
          <body>
            <pre>${content}</pre>
          </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.focus();
      setTimeout(() => {
        printWindow.print();
        printWindow.close();
      }, 500);
    }
  };

  const textareaClass = "w-full h-80 px-4 py-3 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep font-mono resize-y";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Thiết lập & In hợp đồng" size="lg">
      <div className="space-y-4">
        {error && (
          <div className="rounded-xl bg-amber-50 border border-amber-100 p-3 text-xs text-amber-700">{error}</div>
        )}

        <div className="text-xs text-slate-500 bg-slate-50 p-3 rounded-xl">
          <p className="font-bold mb-1">Các từ khóa thay thế tự động:</p>
          <div className="grid grid-cols-3 gap-1 font-mono text-[10px]">
            <span>{"{{TODAY}}"} : Ngày in</span>
            <span>{"{{MOTEL_NAME}}"} : Khu trọ</span>
            <span>{"{{MOTEL_ADDRESS}}"} : Địa chỉ trọ</span>
            <span>{"{{TENANT_NAME}}"} : Tên khách</span>
            <span>{"{{TENANT_CCCD}}"} : CCCD khách</span>
            <span>{"{{TENANT_PHONE}}"} : SĐT khách</span>
            <span>{"{{ROOM_NUMBER}}"} : Số phòng</span>
            <span>{"{{RENT_PRICE}}"} : Tiền phòng</span>
            <span>{"{{DEPOSIT_AMOUNT}}"} : Tiền cọc</span>
            <span>{"{{BILLING_DATE}}"} : Ngày đóng tiền</span>
            <span>{"{{START_DATE}}"} : Ngày bắt đầu</span>
            <span>{"{{END_DATE}}"} : Ngày kết thúc</span>
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-sm font-semibold text-slate-700">Soạn thảo nội dung mẫu hợp đồng</label>
          <textarea
            value={templateText}
            onChange={(e) => setTemplateText(e.target.value)}
            className={textareaClass}
          />
        </div>

        <div className="flex justify-between items-center pt-4 border-t border-slate-100">
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={handleResetTemplate}>Đặt lại mặc định</Button>
            <Button variant="outline" size="sm" onClick={handleSaveTemplate}>Lưu mẫu</Button>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose}>Đóng</Button>
            <Button onClick={handlePrint} disabled={loading}>
              {loading ? "Đang tải dữ liệu..." : "In hợp đồng"}
            </Button>
          </div>
        </div>
      </div>
    </Modal>
  );
}

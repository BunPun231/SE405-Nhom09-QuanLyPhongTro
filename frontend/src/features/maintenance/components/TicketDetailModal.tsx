import React from "react";
import { MaintenanceTicketResponse } from "@/services/maintenanceService";
import { X, CheckCircle2, Image as ImageIcon, User, MapPin, AlertCircle, Calendar } from "lucide-react";

interface TicketDetailModalProps {
  ticket: MaintenanceTicketResponse | null;
  isOpen: boolean;
  onClose: () => void;
}

export function TicketDetailModal({ ticket, isOpen, onClose }: TicketDetailModalProps) {
  if (!isOpen || !ticket) return null;

  const statusBadge = (status: string) => {
    switch (status) {
      case "OPEN":
        return <span className="inline-flex rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-800">Chờ xử lý</span>;
      case "PROCESSING":
        return <span className="inline-flex rounded-full bg-blue-100 px-3 py-1 text-xs font-semibold text-blue-800">Đang xử lý</span>;
      case "COMPLETED":
        return <span className="inline-flex rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-800">Đã hoàn thành</span>;
      case "CANCELLED":
        return <span className="inline-flex rounded-full bg-rose-100 px-3 py-1 text-xs font-semibold text-rose-800">Đã hủy</span>;
      default:
        return <span className="inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-800">{status}</span>;
    }
  };

  const priorityLabel = (prio: string) => {
    switch (prio) {
      case "LOW": return "Thấp";
      case "MEDIUM": return "Trung bình";
      case "HIGH": return "Cao";
      case "URGENT": return "Khẩn cấp";
      default: return prio;
    }
  };

  const categoryLabel = (cat: string) => {
    switch (cat) {
      case "DIEN_NUOC": return "Điện nước";
      case "THIET_BI": return "Thiết bị";
      case "XAY_DUNG": return "Xây dựng / Cấu trúc";
      case "AN_NINH": return "An ninh";
      default: return cat;
    }
  };

  return (
    <div className="fixed inset-0 !mt-0 !top-0 z-[9999] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-100 p-6 space-y-6">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100">
          <div>
            <span className="text-xs font-bold uppercase tracking-wide text-indigo-600">Chi tiết Phiếu Bảo Trì #{ticket.id}</span>
            <h2 className="text-xl font-bold text-slate-900 mt-0.5">Phòng {ticket.roomNumber}</h2>
          </div>
          <div className="flex items-center gap-3">
            {statusBadge(ticket.status)}
            <button onClick={onClose} className="text-slate-400 hover:text-slate-600 p-1.5 rounded-xl hover:bg-slate-100 transition">
              <X size={20} />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div className="bg-slate-50 p-3.5 rounded-xl space-y-2 border border-slate-100">
            <div className="flex items-center gap-2 text-slate-600">
              <MapPin size={16} className="text-indigo-500" />
              <span>Phòng: <strong className="text-slate-900">Phòng {ticket.roomNumber}</strong></span>
            </div>
            <div className="flex items-center gap-2 text-slate-600">
              <User size={16} className="text-indigo-500" />
              <span>Người báo: <strong className="text-slate-900">{ticket.reporterName}</strong></span>
            </div>
            <div className="flex items-center gap-2 text-slate-600">
              <User size={16} className="text-indigo-500" />
              <span>KTV phụ trách: <strong className="text-indigo-700">{ticket.technicianName || "Chưa phân công"}</strong></span>
            </div>
          </div>

          <div className="bg-slate-50 p-3.5 rounded-xl space-y-2 border border-slate-100">
            <div className="flex items-center gap-2 text-slate-600">
              <AlertCircle size={16} className="text-amber-500" />
              <span>Danh mục: <strong className="text-slate-900">{categoryLabel(ticket.category)}</strong></span>
            </div>
            <div className="flex items-center gap-2 text-slate-600">
              <Calendar size={16} className="text-blue-500" />
              <span>Ngày tạo: <strong className="text-slate-900">{new Date(ticket.createdAt).toLocaleString("vi-VN")}</strong></span>
            </div>
            <div className="flex items-center gap-2 text-slate-600">
              <span className="inline-block w-4 h-4 rounded-full bg-rose-500 text-white text-[10px] font-bold text-center leading-4">!</span>
              <span>Mức độ: <strong className="text-rose-600">{priorityLabel(ticket.priority)}</strong></span>
            </div>
          </div>
        </div>

        <div className="space-y-2">
          <h4 className="text-xs font-bold uppercase text-slate-500 tracking-wider">Mô tả sự cố chi tiết</h4>
          <div className="bg-slate-50 p-4 rounded-xl text-slate-700 text-sm border border-slate-100 leading-relaxed">
            {ticket.description}
          </div>
        </div>

        {ticket.beforeImages && ticket.beforeImages.length > 0 && (
          <div className="space-y-2">
            <h4 className="text-xs font-bold uppercase text-slate-500 tracking-wider flex items-center gap-1.5">
              <ImageIcon size={14} className="text-slate-400" /> Ảnh hiện trạng trước sửa
            </h4>
            <div className="flex gap-3 overflow-x-auto pb-2">
              {ticket.beforeImages.map((img, idx) => (
                <a key={idx} href={img} target="_blank" rel="noreferrer">
                  <img src={img} alt="Before" className="h-20 w-20 object-cover rounded-xl border border-slate-200 shadow-sm hover:opacity-95 transition" />
                </a>
              ))}
            </div>
          </div>
        )}

        {ticket.details && ticket.details.length > 0 && (
          <div className="space-y-3 pt-2 border-t border-slate-100">
            <h4 className="text-xs font-bold uppercase text-emerald-700 tracking-wider flex items-center gap-1.5">
              <CheckCircle2 size={15} className="text-emerald-600" /> Vật tư tiêu hao &amp; Kết quả xử lý
            </h4>
            {ticket.details.map((d) => (
              <div key={d.id} className="bg-emerald-50/50 p-3.5 rounded-xl border border-emerald-100 space-y-2">
                {d.deviceName && d.deviceName !== "N/A" && (
                  <div className="text-xs text-slate-700">
                    Vật tư sử dụng: <strong className="text-slate-900 font-semibold">{d.deviceName}</strong> (Số lượng: <span className="text-indigo-600 font-bold">{d.quantityUsed}</span>)
                  </div>
                )}
                {d.note && (
                  <div className="text-xs text-slate-600 italic">
                    &ldquo;{d.note}&rdquo;
                  </div>
                )}
                {d.afterImages && d.afterImages.length > 0 && (
                  <div className="flex gap-2 pt-1">
                    {d.afterImages.map((imgUrl, i) => (
                      <a key={i} href={imgUrl} target="_blank" rel="noreferrer">
                        <img src={imgUrl} alt="After" className="h-16 w-16 object-cover rounded-lg border border-emerald-200 shadow-sm" />
                      </a>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        <div className="flex items-center justify-end pt-4 border-t border-slate-100">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white hover:bg-slate-800 transition"
          >
            Đóng
          </button>
        </div>
      </div>
    </div>
  );
}

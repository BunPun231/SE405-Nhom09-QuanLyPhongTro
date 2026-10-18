import { useState, useEffect } from "react";
import { maintenanceService, MaintenanceTicketResponse } from "@/services/maintenanceService";
import { technicianService, TechnicianResponse } from "@/services/technicianService";
import { motelService, MotelResult } from "@/services/motelService";
import { deviceService, DeviceResponse } from "@/services/deviceService";
import { useAuthStore } from "@/store/authStore";
import { Hammer, Plus, UserCheck, CheckCircle2, Image as ImageIcon } from "lucide-react";

export function MaintenancePage() {
  const { user } = useAuthStore();
  const roleStr = (user?.role as string) || "";
  const isTenant = roleStr === "TENANT" || roleStr === "RESIDENT";
  const isTechnician = roleStr === "TECHNICIAN";
  const isManager = roleStr === "MANAGER" || roleStr === "ADMIN";

  const [tickets, setTickets] = useState<MaintenanceTicketResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);

  // Modal states
  const [isReportOpen, setIsReportOpen] = useState(false);
  const [isAssignOpen, setIsAssignOpen] = useState(false);
  const [isCompleteOpen, setIsCompleteOpen] = useState(false);
  const [activeTicket, setActiveTicket] = useState<MaintenanceTicketResponse | null>(null);

  // Form states - Tenant Report
  const [roomIdInput, setRoomIdInput] = useState("");
  const [categoryInput, setCategoryInput] = useState("DIEN_NUOC");
  const [descriptionInput, setDescriptionInput] = useState("");
  const [priorityInput, setPriorityInput] = useState("MEDIUM");
  const [beforeFiles, setBeforeFiles] = useState<File[]>([]);

  // Form states - Manager Assign
  const [technicians, setTechnicians] = useState<TechnicianResponse[]>([]);
  const [selectedTechId, setSelectedTechId] = useState("");

  // Form states - Technician Complete
  const [completeNote, setCompleteNote] = useState("");
  const [afterFiles, setAfterFiles] = useState<File[]>([]);
  const [devices, setDevices] = useState<DeviceResponse[]>([]);
  const [selectedDeviceId, setSelectedDeviceId] = useState<number | null>(null);
  const [usedQty, setUsedQty] = useState(1);

  useEffect(() => {
    if (isManager) {
      loadMotels();
    } else if (isTechnician) {
      loadMyTasks();
    } else {
      loadMyTickets();
    }
  }, [user]);

  useEffect(() => {
    if (isManager && selectedMotelId) {
      loadMotelTickets(selectedMotelId);
    }
  }, [selectedMotelId]);

  const loadMotels = async () => {
    try {
      const pageData = await motelService.list();
      setMotels(pageData.content);
      if (pageData.content.length > 0) setSelectedMotelId(pageData.content[0].id);
    } catch (e) {
      console.error("Load motels failed", e);
    }
  };

  const loadMotelTickets = async (motelId: number) => {
    setLoading(true);
    try {
      const res = await maintenanceService.getMotelTickets(motelId);
      setTickets(res.content);
    } catch (e) {
      console.error("Load tickets failed", e);
    } finally {
      setLoading(false);
    }
  };

  const loadMyTasks = async () => {
    setLoading(true);
    try {
      const res = await maintenanceService.getMyTasks();
      setTickets(res.content);
    } catch (e) {
      console.error("Load tasks failed", e);
    } finally {
      setLoading(false);
    }
  };

  const loadMyTickets = async () => {
    setLoading(true);
    try {
      const res = await maintenanceService.getMyTickets();
      setTickets(res.content);
    } catch (e) {
      console.error("Load my tickets failed", e);
    } finally {
      setLoading(false);
    }
  };

  const handleReportSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!roomIdInput || !descriptionInput) return;

    try {
      setLoading(true);
      await maintenanceService.createTicket(
        {
          roomId: Number(roomIdInput),
          category: categoryInput,
          description: descriptionInput,
          priority: priorityInput,
        },
        beforeFiles
      );
      alert("Gửi báo cáo sự cố thành công! Backend đã upload ảnh lên Cloudinary.");
      setIsReportOpen(false);
      resetReportForm();
      if (isManager && selectedMotelId) loadMotelTickets(selectedMotelId);
      else loadMyTickets();
    } catch (error: any) {
      alert(error.response?.data?.message || "Tạo phiếu bảo trì thất bại");
    } finally {
      setLoading(false);
    }
  };

  const openAssignModal = async (ticket: MaintenanceTicketResponse) => {
    setActiveTicket(ticket);
    try {
      const res = await technicianService.getTechnicians();
      setTechnicians(res.content);
      setSelectedTechId(res.content[0]?.userId || "");
      setIsAssignOpen(true);
    } catch (e) {
      alert("Không thể tải danh sách KTV");
    }
  };

  const handleAssignSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeTicket || !selectedTechId) return;

    try {
      await maintenanceService.assignTechnician(activeTicket.id, selectedTechId);
      alert("Phân công KTV thành công!");
      setIsAssignOpen(false);
      if (selectedMotelId) loadMotelTickets(selectedMotelId);
    } catch (e) {
      alert("Phân công thất bại");
    }
  };

  const openCompleteModal = async (ticket: MaintenanceTicketResponse) => {
    setActiveTicket(ticket);
    setCompleteNote("");
    setAfterFiles([]);
    setSelectedDeviceId(null);
    setUsedQty(1);
    const motelIdToUse = ticket.motelId || selectedMotelId;
    if (motelIdToUse) {
      try {
        const res = await deviceService.getDevices(motelIdToUse);
        setDevices(res.content);
      } catch (e) {
        setDevices([]);
      }
    } else {
      setDevices([]);
    }
    setIsCompleteOpen(true);
  };

  const handleCompleteSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeTicket) return;

    const usedDevices = selectedDeviceId
      ? [{ deviceId: selectedDeviceId, quantityUsed: usedQty }]
      : [];

    try {
      setLoading(true);
      await maintenanceService.completeTicket(
        activeTicket.id,
        { usedDevices, note: completeNote },
        afterFiles
      );
      alert("Hoàn thành bảo trì thành công! Backend đã cập nhật trạng thái và trừ kho vật tư.");
      setIsCompleteOpen(false);
      if (isTechnician) loadMyTasks();
      else if (selectedMotelId) loadMotelTickets(selectedMotelId);
    } catch (error: any) {
      alert(error.response?.data?.message || "Hoàn thành phiếu bảo trì thất bại");
    } finally {
      setLoading(false);
    }
  };

  const resetReportForm = () => {
    setRoomIdInput("");
    setCategoryInput("DIEN_NUOC");
    setDescriptionInput("");
    setPriorityInput("MEDIUM");
    setBeforeFiles([]);
  };

  const statusBadge = (status: string) => {
    switch (status) {
      case "OPEN":
        return <span className="inline-flex rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-semibold text-amber-800">Chờ xử lý</span>;
      case "PROCESSING":
        return <span className="inline-flex rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-semibold text-blue-800">Đang xử lý</span>;
      case "COMPLETED":
        return <span className="inline-flex rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-semibold text-emerald-800">Đã hoàn thành</span>;
      case "CANCELLED":
        return <span className="inline-flex rounded-full bg-rose-100 px-2.5 py-0.5 text-xs font-semibold text-rose-800">Đã hủy</span>;
      default:
        return <span className="inline-flex rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-800">{status}</span>;
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            <Hammer className="h-7 w-7 text-indigo-600" />
            {isTechnician ? "Nhiệm vụ Bảo trì được giao" : isTenant ? "Báo sự cố & Bảo trì" : "Quản lý Bảo trì & Sự cố"}
          </h1>
          <p className="text-sm text-slate-500 mt-1">Theo dõi, phân công và khắc phục hỏng hóc tài sản phòng trọ</p>
        </div>

        <div className="flex items-center gap-3">
          {isManager && motels.length > 0 && (
            <select
              value={selectedMotelId || ""}
              onChange={(e) => setSelectedMotelId(Number(e.target.value))}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-medium text-slate-700 shadow-sm focus:border-indigo-500 focus:outline-none"
            >
              {motels.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name}
                </option>
              ))}
            </select>
          )}

          {!isTechnician && (
            <button
              onClick={() => {
                resetReportForm();
                setIsReportOpen(true);
              }}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-indigo-700 transition"
            >
              <Plus className="h-4 w-4" />
              Báo sự cố mới
            </button>
          )}
        </div>
      </div>

      {/* Ticket Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-full py-12 text-center text-slate-400">Đang tải phiếu bảo trì...</div>
        ) : tickets.length === 0 ? (
          <div className="col-span-full py-12 text-center text-slate-400">Chưa có thông tin sự cố nào</div>
        ) : (
          tickets.map((ticket) => (
            <div key={ticket.id} className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:shadow-md transition space-y-4">
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-xs font-bold text-indigo-600 uppercase tracking-wide">Phòng {ticket.roomNumber}</span>
                  <h3 className="font-semibold text-slate-900 text-base">{ticket.description}</h3>
                </div>
                {statusBadge(ticket.status)}
              </div>

              <div className="text-xs text-slate-500 space-y-1">
                <div>Người báo: <span className="font-medium text-slate-700">{ticket.reporterName}</span></div>
                <div>KTV phụ trách: <span className="font-medium text-indigo-700">{ticket.technicianName || "Chưa phân công"}</span></div>
                <div>Thời gian tạo: {new Date(ticket.createdAt).toLocaleString("vi-VN")}</div>
              </div>

              {/* Before Images */}
              {ticket.beforeImages && ticket.beforeImages.length > 0 && (
                <div>
                  <span className="text-xs font-medium text-slate-600 flex items-center gap-1 mb-1.5">
                    <ImageIcon className="h-3.5 w-3.5 text-slate-400" /> Ảnh hiện trạng trước sửa:
                  </span>
                  <div className="flex gap-2 overflow-x-auto pb-1">
                    {ticket.beforeImages.map((imgUrl, i) => (
                      <a key={i} href={imgUrl} target="_blank" rel="noreferrer">
                        <img src={imgUrl} alt="Before" className="h-16 w-16 object-cover rounded-lg border border-slate-200 hover:opacity-90" />
                      </a>
                    ))}
                  </div>
                </div>
              )}

              {/* After Images & Details */}
              {ticket.details && ticket.details.length > 0 && (
                <div className="border-t border-slate-100 pt-2 space-y-2">
                  <span className="text-xs font-medium text-emerald-700 flex items-center gap-1">
                    <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" /> Chi tiết xử lý &amp; Ảnh hoàn thành:
                  </span>
                  {ticket.details.map((d) => (
                    <div key={d.id} className="text-xs bg-slate-50 p-2 rounded-lg space-y-1">
                      {d.deviceName && d.deviceName !== "N/A" && (
                        <div>Vật tư thay: <strong>{d.deviceName}</strong> (Số lượng: {d.quantityUsed})</div>
                      )}
                      {d.note && <div className="text-slate-600 italic">Ghi chú: {d.note}</div>}
                      {d.afterImages && d.afterImages.length > 0 && (
                        <div className="flex gap-1.5 pt-1">
                          {d.afterImages.map((url, idx) => (
                            <a key={idx} href={url} target="_blank" rel="noreferrer">
                              <img src={url} alt="After" className="h-12 w-12 object-cover rounded border border-emerald-200" />
                            </a>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Actions */}
              <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                {isManager && ticket.status === "OPEN" && (
                  <button
                    onClick={() => openAssignModal(ticket)}
                    className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-50 px-3 py-1.5 text-xs font-medium text-indigo-700 hover:bg-indigo-100"
                  >
                    <UserCheck className="h-3.5 w-3.5" /> Phân công KTV
                  </button>
                )}
                {(isTechnician || isManager) && ticket.status !== "COMPLETED" && (
                  <button
                    onClick={() => openCompleteModal(ticket)}
                    className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-emerald-700"
                  >
                    <CheckCircle2 className="h-3.5 w-3.5" /> Cập nhật hoàn thành
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal Report Incident */}
      {isReportOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Báo cáo Sự cố mới</h2>
            <form onSubmit={handleReportSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mã/ID Phòng *</label>
                <input
                  type="number"
                  required
                  value={roomIdInput}
                  onChange={(e) => setRoomIdInput(e.target.value)}
                  placeholder="Nhập ID phòng"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Danh mục</label>
                <select
                  value={categoryInput}
                  onChange={(e) => setCategoryInput(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                >
                  <option value="DIEN_NUOC">Điện nước</option>
                  <option value="DIEN_LANG">Điện lạnh (Điều hòa/Tủ lạnh)</option>
                  <option value="DO_GO">Đồ gỗ / Nội thất</option>
                  <option value="KHOA_CUA">Khóa cửa / An ninh</option>
                  <option value="KHAC">Khác</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mức độ ưu tiên</label>
                <select
                  value={priorityInput}
                  onChange={(e) => setPriorityInput(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                >
                  <option value="LOW">Thấp (Low)</option>
                  <option value="MEDIUM">Trung bình (Medium)</option>
                  <option value="HIGH">Cao (High)</option>
                  <option value="URGENT">Khẩn cấp (Urgent)</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mô tả chi tiết sự cố *</label>
                <textarea
                  required
                  rows={3}
                  value={descriptionInput}
                  onChange={(e) => setDescriptionInput(e.target.value)}
                  placeholder="Ví dụ: Vòi nước bị rò rỉ mạnh ở nhà vệ sinh..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Hình ảnh hiện trạng (upload qua Backend vào Cloudinary)</label>
                <input
                  type="file"
                  multiple
                  accept="image/*"
                  onChange={(e) => setBeforeFiles(e.target.files ? Array.from(e.target.files) : [])}
                  className="w-full text-xs text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsReportOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
                >
                  {loading ? "Đang xử lý..." : "Gửi phản ánh"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Assign Technician */}
      {isAssignOpen && activeTicket && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Phân công Kỹ thuật viên</h2>
            <form onSubmit={handleAssignSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Chọn KTV *</label>
                <select
                  value={selectedTechId}
                  onChange={(e) => setSelectedTechId(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                >
                  {technicians.map((t) => (
                    <option key={t.userId} value={t.userId}>
                      {t.fullName} ({t.phone}) - {t.expertise?.join(", ") || "Tổng hợp"}
                    </option>
                  ))}
                </select>
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsAssignOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
                >
                  Xác nhận phân công
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Complete Ticket */}
      {isCompleteOpen && activeTicket && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Cập nhật Hoàn thành Bảo trì</h2>
            <form onSubmit={handleCompleteSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Vật tư / Thiết bị đã dùng (từ Kho)</label>
                <select
                  value={selectedDeviceId || ""}
                  onChange={(e) => {
                    const id = e.target.value ? Number(e.target.value) : null;
                    setSelectedDeviceId(id);
                    setUsedQty(1);
                  }}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                >
                  <option value="">-- Không sử dụng vật tư kho --</option>
                  {devices.map((d) => (
                    <option key={d.id} value={d.id} disabled={d.availableQuantity <= 0}>
                      {d.name} ({d.brand || "N/A"}) - Còn tồn: {d.availableQuantity}
                    </option>
                  ))}
                </select>
              </div>
              {selectedDeviceId && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">
                    Số lượng vật tư (Tối đa: {devices.find((d) => d.id === selectedDeviceId)?.availableQuantity ?? 0})
                  </label>
                  <input
                    type="number"
                    min="1"
                    max={devices.find((d) => d.id === selectedDeviceId)?.availableQuantity ?? 999}
                    value={usedQty}
                    onChange={(e) => setUsedQty(Number(e.target.value))}
                    className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                  />
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ghi chú sửa chữa</label>
                <textarea
                  rows={2}
                  value={completeNote}
                  onChange={(e) => setCompleteNote(e.target.value)}
                  placeholder="Ví dụ: Đã thay dây dẫn điện và kiểm tra lại hệ thống..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ảnh chụp kết quả hoàn thành (upload qua Backend vào Cloudinary)</label>
                <input
                  type="file"
                  multiple
                  accept="image/*"
                  onChange={(e) => setAfterFiles(e.target.files ? Array.from(e.target.files) : [])}
                  className="w-full text-xs text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsCompleteOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
                >
                  {loading ? "Đang xử lý..." : "Xác nhận hoàn thành"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

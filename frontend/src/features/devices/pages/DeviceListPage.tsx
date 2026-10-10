import { useState, useEffect } from "react";
import { deviceService, DeviceResponse, DeviceMovementLogResponse } from "@/services/deviceService";
import { motelService, MotelResult } from "@/services/motelService";
import { Wrench, Plus, Edit, Trash2, ArrowRightLeft, History } from "lucide-react";

export function DeviceListPage() {
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [devices, setDevices] = useState<DeviceResponse[]>([]);
  const [loading, setLoading] = useState(false);

  // Modal states
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isAssignOpen, setIsAssignOpen] = useState(false);
  const [isLogsOpen, setIsLogsOpen] = useState(false);

  const [activeDevice, setActiveDevice] = useState<DeviceResponse | null>(null);
  const [movementLogs, setMovementLogs] = useState<DeviceMovementLogResponse[]>([]);

  // Form states
  const [formName, setFormName] = useState("");
  const [formBrand, setFormBrand] = useState("");
  const [formPrice, setFormPrice] = useState("");
  const [formStatus, setFormStatus] = useState("IN_STOCK");

  // Assign form states
  const [assignRoomId, setAssignRoomId] = useState("");
  const [assignQuantity, setAssignQuantity] = useState("1");
  const [assignCondition, setAssignCondition] = useState("GOOD");
  const [assignNote, setAssignNote] = useState("");

  useEffect(() => {
    loadMotels();
  }, []);

  useEffect(() => {
    if (selectedMotelId) {
      loadDevices(selectedMotelId);
    }
  }, [selectedMotelId]);

  const loadMotels = async () => {
    try {
      const pageData = await motelService.list();
      setMotels(pageData.content);
      if (pageData.content.length > 0) {
        setSelectedMotelId(pageData.content[0].id);
      }
    } catch (error) {
      console.error("Failed to load motels", error);
    }
  };

  const loadDevices = async (motelId: number) => {
    setLoading(true);
    try {
      const res = await deviceService.getDevices(motelId);
      setDevices(res.content);
    } catch (error) {
      console.error("Failed to load devices", error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !formName) return;
    try {
      await deviceService.createDevice(selectedMotelId, {
        name: formName,
        brand: formBrand,
        purchasePrice: formPrice ? Number(formPrice) : undefined,
      });
      setIsAddOpen(false);
      resetForm();
      loadDevices(selectedMotelId);
    } catch (error) {
      alert("Tạo thiết bị thất bại");
    }
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice) return;
    try {
      await deviceService.updateDevice(selectedMotelId, activeDevice.id, {
        name: formName,
        brand: formBrand,
        purchasePrice: formPrice ? Number(formPrice) : undefined,
        status: formStatus,
      });
      setIsEditOpen(false);
      resetForm();
      loadDevices(selectedMotelId);
    } catch (error) {
      alert("Cập nhật thất bại");
    }
  };

  const handleDelete = async (deviceId: number) => {
    if (!selectedMotelId || !confirm("Bạn có chắc chắn muốn xóa thiết bị này khỏi danh mục?")) return;
    try {
      await deviceService.deleteDevice(selectedMotelId, deviceId);
      loadDevices(selectedMotelId);
    } catch (error) {
      alert("Xóa thất bại");
    }
  };

  const handleAssignSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice || !assignRoomId) return;
    try {
      await deviceService.assignDevice(selectedMotelId, activeDevice.id, {
        roomId: Number(assignRoomId),
        assignedQuantity: Number(assignQuantity),
        condition: assignCondition,
        note: assignNote,
      });
      setIsAssignOpen(false);
      loadDevices(selectedMotelId);
      alert("Gán thiết bị thành công!");
    } catch (error) {
      alert("Gán thiết bị thất bại");
    }
  };

  const handleViewLogs = async (device: DeviceResponse) => {
    if (!selectedMotelId) return;
    setActiveDevice(device);
    try {
      const logs = await deviceService.getMovementLogs(selectedMotelId, device.id);
      setMovementLogs(logs);
      setIsLogsOpen(true);
    } catch (error) {
      alert("Không thể tải nhật ký");
    }
  };

  const resetForm = () => {
    setFormName("");
    setFormBrand("");
    setFormPrice("");
    setFormStatus("IN_STOCK");
    setActiveDevice(null);
  };

  const openEdit = (device: DeviceResponse) => {
    setActiveDevice(device);
    setFormName(device.name);
    setFormBrand(device.brand || "");
    setFormPrice(device.purchasePrice ? String(device.purchasePrice) : "");
    setFormStatus(device.status);
    setIsEditOpen(true);
  };

  const openAssign = (device: DeviceResponse) => {
    setActiveDevice(device);
    setAssignRoomId("");
    setAssignQuantity("1");
    setAssignCondition("GOOD");
    setAssignNote("");
    setIsAssignOpen(true);
  };

  const statusBadge = (device: DeviceResponse) => {
    const inUse = device.inUseQuantity || 0;
    switch (device.status) {
      case "IN_STOCK":
        return (
          <span className="inline-flex rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-semibold text-emerald-800">
            Trong kho {inUse > 0 ? `(Đang gán: ${inUse})` : "(Sẵn sàng)"}
          </span>
        );
      case "IN_USE":
        return (
          <span className="inline-flex rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-semibold text-blue-800">
            Đang sử dụng (Đang gán: {inUse})
          </span>
        );
      case "BROKEN":
        return <span className="inline-flex rounded-full bg-rose-100 px-2.5 py-0.5 text-xs font-semibold text-rose-800">Hỏng</span>;
      case "REPAIRING":
        return <span className="inline-flex rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-semibold text-amber-800">Đang sửa chữa</span>;
      default:
        return <span className="inline-flex rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-semibold text-slate-800">{device.status}</span>;
    }
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            <Wrench className="h-7 w-7 text-indigo-600" />
            Quản lý Kho Thiết bị
          </h1>
          <p className="text-sm text-slate-500 mt-1">Danh mục tài sản, đồ dùng đang trang bị tại các khu trọ</p>
        </div>

        <div className="flex items-center gap-3">
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

          <button
            onClick={() => {
              resetForm();
              setIsAddOpen(true);
            }}
            className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-indigo-700 transition"
          >
            <Plus className="h-4 w-4" />
            Thêm thiết bị
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-600">
            <thead className="bg-slate-50 text-xs font-semibold uppercase text-slate-500 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3">Tên thiết bị</th>
                <th className="px-6 py-3">Thương hiệu</th>
                <th className="px-6 py-3">Giá mua (VND)</th>
                <th className="px-6 py-3">Tình trạng & SL gán</th>
                <th className="px-6 py-3 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-slate-400">Đang tải danh sách...</td>
                </tr>
              ) : devices.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-slate-400">Chưa có thiết bị nào trong kho</td>
                </tr>
              ) : (
                devices.map((device) => (
                  <tr key={device.id} className="hover:bg-slate-50 transition">
                    <td className="px-6 py-4 font-semibold text-slate-900">{device.name}</td>
                    <td className="px-6 py-4 text-slate-600">{device.brand || "—"}</td>
                    <td className="px-6 py-4 text-slate-600 font-medium">
                      {device.purchasePrice ? device.purchasePrice.toLocaleString("vi-VN") : "—"}
                    </td>
                    <td className="px-6 py-4">{statusBadge(device)}</td>
                    <td className="px-6 py-4 text-right space-x-2">
                      <button
                        onClick={() => openAssign(device)}
                        title="Gán vào phòng"
                        className="inline-flex items-center gap-1 rounded-md bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700 hover:bg-blue-100"
                      >
                        <ArrowRightLeft className="h-3.5 w-3.5" /> Gán phòng
                      </button>
                      <button
                        onClick={() => handleViewLogs(device)}
                        title="Nhật ký di chuyển"
                        className="inline-flex items-center gap-1 rounded-md bg-purple-50 px-2.5 py-1 text-xs font-medium text-purple-700 hover:bg-purple-100"
                      >
                        <History className="h-3.5 w-3.5" /> Lịch sử
                      </button>
                      <button
                        onClick={() => openEdit(device)}
                        className="p-1 text-slate-400 hover:text-indigo-600"
                      >
                        <Edit className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(device.id)}
                        className="p-1 text-slate-400 hover:text-rose-600"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Add Device */}
      {isAddOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Thêm Thiết bị mới</h2>
            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Tên thiết bị *</label>
                <input
                  type="text"
                  required
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  placeholder="Ví dụ: Máy lạnh Inverter 1.5 HP"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Thương hiệu / Hãng sản xuất</label>
                <input
                  type="text"
                  value={formBrand}
                  onChange={(e) => setFormBrand(e.target.value)}
                  placeholder="Ví dụ: Panasonic, Casper..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Giá mua (VND)</label>
                <input
                  type="number"
                  value={formPrice}
                  onChange={(e) => setFormPrice(e.target.value)}
                  placeholder="0"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsAddOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
                >
                  Tạo mới
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Edit Device */}
      {isEditOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Sửa thông tin Thiết bị</h2>
            <form onSubmit={handleUpdate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Tên thiết bị *</label>
                <input
                  type="text"
                  required
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Thương hiệu</label>
                <input
                  type="text"
                  value={formBrand}
                  onChange={(e) => setFormBrand(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Giá mua (VND)</label>
                <input
                  type="number"
                  value={formPrice}
                  onChange={(e) => setFormPrice(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Trạng thái</label>
                <select
                  value={formStatus}
                  onChange={(e) => setFormStatus(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                >
                  <option value="IN_STOCK">Trong kho</option>
                  <option value="IN_USE">Đang sử dụng</option>
                  <option value="BROKEN">Hỏng</option>
                  <option value="REPAIRING">Đang sửa chữa</option>
                </select>
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsEditOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
                >
                  Cập nhật
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Assign Device */}
      {isAssignOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Gán Thiết bị vào Phòng</h2>
            <p className="text-xs text-slate-500 mb-4">
              Thiết bị: <strong className="text-indigo-600">{activeDevice.name}</strong> (Hiện đã gán: {activeDevice.inUseQuantity || 0})
            </p>
            <form onSubmit={handleAssignSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mã/ID Phòng *</label>
                <input
                  type="number"
                  required
                  value={assignRoomId}
                  onChange={(e) => setAssignRoomId(e.target.value)}
                  placeholder="Nhập Room ID"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng gán</label>
                <input
                  type="number"
                  value={assignQuantity}
                  onChange={(e) => setAssignQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Tình trạng</label>
                <select
                  value={assignCondition}
                  onChange={(e) => setAssignCondition(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                >
                  <option value="NEW">Mới</option>
                  <option value="GOOD">Tốt</option>
                  <option value="BROKEN">Hỏng</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ghi chú</label>
                <input
                  type="text"
                  value={assignNote}
                  onChange={(e) => setAssignNote(e.target.value)}
                  placeholder="Ví dụ: Lắp ở mảng tường phía đông"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
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
                  Xác nhận gán
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Movement Logs */}
      {isLogsOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Lịch sử Di chuyển Thiết bị</h2>
            <p className="text-xs text-slate-500 mb-4">Thiết bị: <strong className="text-indigo-600">{activeDevice.name}</strong></p>

            <div className="max-h-80 overflow-y-auto space-y-3 pr-1">
              {movementLogs.length === 0 ? (
                <p className="text-sm text-slate-400 text-center py-6">Chưa có thông tin di chuyển</p>
              ) : (
                movementLogs.map((log) => (
                  <div key={log.id} className="rounded-lg border border-slate-200 p-3 bg-slate-50 text-xs text-slate-700 space-y-1">
                    <div className="flex items-center justify-between font-semibold">
                      <span className={log.action === "ASSIGN" ? "text-emerald-600" : "text-rose-600"}>
                        {log.action === "ASSIGN" ? "Gán vào phòng" : "Thu hồi từ phòng"}
                      </span>
                      <span className="text-slate-400">{new Date(log.timestamp).toLocaleString("vi-VN")}</span>
                    </div>
                    <div>
                      {log.fromRoomId && <span>Từ phòng ID: {log.fromRoomId} </span>}
                      {log.toRoomId && <span>Đến phòng ID: {log.toRoomId}</span>}
                    </div>
                    {log.note && <div className="text-slate-500 italic">Ghi chú: {log.note}</div>}
                  </div>
                ))
              )}
            </div>

            <div className="flex justify-end pt-4">
              <button
                type="button"
                onClick={() => setIsLogsOpen(false)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

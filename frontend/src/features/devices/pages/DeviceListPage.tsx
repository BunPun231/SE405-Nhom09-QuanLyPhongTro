import { useState, useEffect } from "react";
import { deviceService, DeviceResponse, DeviceMovementLogResponse } from "@/services/deviceService";
import { motelService, MotelResult } from "@/services/motelService";
import { Wrench, Plus, Edit, Trash2, ArrowRightLeft, History, PlusCircle, MinusCircle, RotateCcw, Hammer, CheckCircle } from "lucide-react";

export function DeviceListPage() {
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [devices, setDevices] = useState<DeviceResponse[]>([]);
  const [loading, setLoading] = useState(false);

  // Modal states
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [isAssignOpen, setIsAssignOpen] = useState(false);
  const [isImportOpen, setIsImportOpen] = useState(false);
  const [isDisposeOpen, setIsDisposeOpen] = useState(false);
  const [isRecallOpen, setIsRecallOpen] = useState(false);
  const [isLogsOpen, setIsLogsOpen] = useState(false);
  const [isSendToRepairOpen, setIsSendToRepairOpen] = useState(false);
  const [isFinishRepairOpen, setIsFinishRepairOpen] = useState(false);

  const [activeDevice, setActiveDevice] = useState<DeviceResponse | null>(null);
  const [movementLogs, setMovementLogs] = useState<DeviceMovementLogResponse[]>([]);

  // Form states
  const [formName, setFormName] = useState("");
  const [formBrand, setFormBrand] = useState("");
  const [formPrice, setFormPrice] = useState("");
  const [formTotalQuantity, setFormTotalQuantity] = useState("1");

  // Assign form states
  const [assignRoomId, setAssignRoomId] = useState("");
  const [assignQuantity, setAssignQuantity] = useState("1");
  const [assignCondition, setAssignCondition] = useState("GOOD");
  const [assignNote, setAssignNote] = useState("");

  // Import form states
  const [importQuantity, setImportQuantity] = useState("1");
  const [importNote, setImportNote] = useState("");

  // Dispose form states
  const [disposeQuantity, setDisposeQuantity] = useState("1");
  const [disposeReason, setDisposeReason] = useState("");

  // Recall form states
  const [recallRoomId, setRecallRoomId] = useState("");
  const [recallQuantity, setRecallQuantity] = useState("1");
  const [recallNote, setRecallNote] = useState("");

  // Send-to-repair form states
  const [repairQuantity, setRepairQuantity] = useState("1");
  const [repairNote, setRepairNote] = useState("");

  // Finish-repair form states
  const [finishRepairQuantity, setFinishRepairQuantity] = useState("1");
  const [finishRepairNote, setFinishRepairNote] = useState("");

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
        totalQuantity: formTotalQuantity ? Number(formTotalQuantity) : 1,
      });
      setIsAddOpen(false);
      resetForm();
      loadDevices(selectedMotelId);
    } catch (error: any) {
      alert(error.response?.data?.message || "Tạo thiết bị thất bại");
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
      });
      setIsEditOpen(false);
      resetForm();
      loadDevices(selectedMotelId);
    } catch (error: any) {
      alert(error.response?.data?.message || "Cập nhật thất bại");
    }
  };

  const handleImportSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice) return;
    try {
      await deviceService.importStock(selectedMotelId, activeDevice.id, {
        quantity: Number(importQuantity),
        note: importNote,
      });
      setIsImportOpen(false);
      loadDevices(selectedMotelId);
      alert("Nhập thêm vào kho thành công!");
    } catch (error: any) {
      alert(error.response?.data?.message || "Nhập kho thất bại");
    }
  };

  const handleDisposeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice) return;
    try {
      await deviceService.disposeStock(selectedMotelId, activeDevice.id, {
        quantity: Number(disposeQuantity),
        reason: disposeReason,
      });
      setIsDisposeOpen(false);
      loadDevices(selectedMotelId);
      alert("Xuất hủy / Báo hỏng thành công!");
    } catch (error: any) {
      alert(error.response?.data?.message || "Xuất hủy thất bại");
    }
  };

  const handleDelete = async (deviceId: number) => {
    if (!selectedMotelId || !confirm("Bạn có chắc chắn muốn xóa thiết bị này khỏi danh mục?")) return;
    try {
      await deviceService.deleteDevice(selectedMotelId, deviceId);
      loadDevices(selectedMotelId);
    } catch (error: any) {
      alert(error.response?.data?.message || "Xóa thất bại");
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
    } catch (error: any) {
      alert(error.response?.data?.message || "Gán thiết bị thất bại");
    }
  };

  const handleRecallSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice || !recallRoomId) return;
    try {
      await deviceService.recallDevice(selectedMotelId, activeDevice.id, Number(recallRoomId), {
        quantity: recallQuantity ? Number(recallQuantity) : undefined,
        note: recallNote,
      });
      setIsRecallOpen(false);
      loadDevices(selectedMotelId);
      alert("Thu hồi thiết bị từ phòng về kho thành công!");
    } catch (error: any) {
      alert(error.response?.data?.message || "Thu hồi thiết bị thất bại");
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
    setFormTotalQuantity("1");
    setActiveDevice(null);
  };

  const handleSendToRepairSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice) return;
    try {
      await deviceService.sendToRepair(selectedMotelId, activeDevice.id, {
        quantity: Number(repairQuantity),
        note: repairNote,
      });
      setIsSendToRepairOpen(false);
      loadDevices(selectedMotelId);
      alert("Gửi thiết bị đi sửa chữa thành công!");
    } catch (error: any) {
      alert(error.response?.data?.message || "Gửi đi sửa thất bại");
    }
  };

  const handleFinishRepairSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedMotelId || !activeDevice) return;
    try {
      await deviceService.finishRepair(selectedMotelId, activeDevice.id, {
        quantity: Number(finishRepairQuantity),
        note: finishRepairNote,
      });
      setIsFinishRepairOpen(false);
      loadDevices(selectedMotelId);
      alert("Xác nhận sửa xong về kho thành công!");
    } catch (error: any) {
      alert(error.response?.data?.message || "Xác nhận sửa xong thất bại");
    }
  };

  const openSendToRepair = (device: DeviceResponse) => {
    setActiveDevice(device);
    setRepairQuantity("1");
    setRepairNote("");
    setIsSendToRepairOpen(true);
  };

  const openFinishRepair = (device: DeviceResponse) => {
    setActiveDevice(device);
    setFinishRepairQuantity("1");
    setFinishRepairNote("");
    setIsFinishRepairOpen(true);
  };

  const openEdit = (device: DeviceResponse) => {
    setActiveDevice(device);
    setFormName(device.name);
    setFormBrand(device.brand || "");
    setFormPrice(device.purchasePrice ? String(device.purchasePrice) : "");
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

  const openImport = (device: DeviceResponse) => {
    setActiveDevice(device);
    setImportQuantity("1");
    setImportNote("");
    setIsImportOpen(true);
  };

  const openDispose = (device: DeviceResponse) => {
    setActiveDevice(device);
    setDisposeQuantity("1");
    setDisposeReason("");
    setIsDisposeOpen(true);
  };

  const openRecall = (device: DeviceResponse) => {
    setActiveDevice(device);
    setRecallRoomId("");
    setRecallQuantity("1");
    setRecallNote("");
    setIsRecallOpen(true);
  };

  const statusBadge = (device: DeviceResponse) => {
    const avail = device.availableQuantity ?? 0;
    if (avail > 0) {
      return (
        <span className="inline-flex rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-semibold text-emerald-800">
          IN_STOCK (Còn: {avail})
        </span>
      );
    }
    return (
      <span className="inline-flex rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-semibold text-blue-800">
        IN_USE (Hết tồn kho)
      </span>
    );
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            <Wrench className="h-7 w-7 text-indigo-600" />
            Quản lý Kho Thiết bị (Inventory Batch)
          </h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý tổng tồn kho, số lượng đang gán tại các phòng và khả dụng xuất kho</p>
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
            Thêm thiết bị mới
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
                <th className="px-6 py-3 text-center">Tổng kho</th>
                <th className="px-6 py-3 text-center">Đang gán</th>
                <th className="px-6 py-3 text-center text-amber-600">Đang sửa</th>
                <th className="px-6 py-3 text-center">Khả dụng</th>
                <th className="px-6 py-3">Trạng thái kho</th>
                <th className="px-6 py-3 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-6 py-8 text-center text-slate-400">Đang tải danh sách...</td>
                </tr>
              ) : devices.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-8 text-center text-slate-400">Chưa có thiết bị nào trong kho</td>
                </tr>
              ) : (
                devices.map((device) => (
                  <tr key={device.id} className="hover:bg-slate-50 transition">
                    <td className="px-6 py-4 font-semibold text-slate-900">{device.name}</td>
                    <td className="px-6 py-4 text-slate-600">{device.brand || "—"}</td>
                    <td className="px-6 py-4 text-slate-600 font-medium">
                      {device.purchasePrice ? device.purchasePrice.toLocaleString("vi-VN") : "—"}
                    </td>
                    <td className="px-6 py-4 text-center font-bold text-slate-900">{device.totalQuantity ?? 1}</td>
                    <td className="px-6 py-4 text-center font-semibold text-indigo-600">{device.inUseQuantity ?? 0}</td>
                    <td className="px-6 py-4 text-center font-semibold text-amber-600">{device.repairingQuantity ?? 0}</td>
                    <td className="px-6 py-4 text-center font-bold text-emerald-600">{device.availableQuantity ?? 0}</td>
                    <td className="px-6 py-4">{statusBadge(device)}</td>
                    <td className="px-6 py-4 text-right space-x-1.5 whitespace-nowrap">
                      <button
                        onClick={() => openAssign(device)}
                        title="Gán vào phòng"
                        className="inline-flex items-center gap-1 rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 hover:bg-blue-100"
                      >
                        <ArrowRightLeft className="h-3.5 w-3.5" /> Gán
                      </button>
                      {device.inUseQuantity > 0 && (
                        <button
                          onClick={() => openRecall(device)}
                          title="Thu hồi thiết bị từ phòng về kho"
                          className="inline-flex items-center gap-1 rounded-md bg-orange-50 px-2 py-1 text-xs font-medium text-orange-700 hover:bg-orange-100"
                        >
                          <RotateCcw className="h-3.5 w-3.5" /> Thu hồi
                        </button>
                      )}
                      <button
                        onClick={() => openImport(device)}
                        title="Nhập thêm hàng vào kho"
                        className="inline-flex items-center gap-1 rounded-md bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 hover:bg-emerald-100"
                      >
                        <PlusCircle className="h-3.5 w-3.5" /> Nhập
                      </button>
                      <button
                        onClick={() => openDispose(device)}
                        title="Xuất hủy / Báo hỏng khỏi kho"
                        className="inline-flex items-center gap-1 rounded-md bg-amber-50 px-2 py-1 text-xs font-medium text-amber-700 hover:bg-amber-100"
                      >
                        <MinusCircle className="h-3.5 w-3.5" /> Hủy
                      </button>
                      {device.availableQuantity > 0 && (
                        <button
                          onClick={() => openSendToRepair(device)}
                          title="Gửi đi sửa chữa"
                          className="inline-flex items-center gap-1 rounded-md bg-rose-50 px-2 py-1 text-xs font-medium text-rose-700 hover:bg-rose-100"
                        >
                          <Hammer className="h-3.5 w-3.5" /> Gửi sửa
                        </button>
                      )}
                      {device.repairingQuantity > 0 && (
                        <button
                          onClick={() => openFinishRepair(device)}
                          title="Sửa xong – trả về kho"
                          className="inline-flex items-center gap-1 rounded-md bg-teal-50 px-2 py-1 text-xs font-medium text-teal-700 hover:bg-teal-100"
                        >
                          <CheckCircle className="h-3.5 w-3.5" /> Sửa xong
                        </button>
                      )}
                      <button
                        onClick={() => handleViewLogs(device)}
                        title="Nhật ký biến động kho"
                        className="inline-flex items-center gap-1 rounded-md bg-purple-50 px-2 py-1 text-xs font-medium text-purple-700 hover:bg-purple-100"
                      >
                        <History className="h-3.5 w-3.5" /> Log
                      </button>
                      <button
                        onClick={() => openEdit(device)}
                        title="Sửa thông tin"
                        className="p-1 text-slate-400 hover:text-indigo-600"
                      >
                        <Edit className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(device.id)}
                        title="Xóa thiết bị"
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
            <h2 className="text-lg font-bold text-slate-900 mb-4">Nhập Kho Thiết bị Mới</h2>
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
                <label className="block text-sm font-medium text-slate-700 mb-1">Giá mua / Đơn giá (VND)</label>
                <input
                  type="number"
                  value={formPrice}
                  onChange={(e) => setFormPrice(e.target.value)}
                  placeholder="0"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Tổng số lượng nhập kho *</label>
                <input
                  type="number"
                  min="1"
                  required
                  value={formTotalQuantity}
                  onChange={(e) => setFormTotalQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none font-bold text-indigo-600"
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
                  Nhập kho
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Edit Device - Only General Info */}
      {isEditOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Sửa Thông tin Thiết bị</h2>
            <p className="text-xs text-slate-500 mb-4">
              Tổng kho: <strong>{activeDevice.totalQuantity}</strong> | Khả dụng: <strong className="text-emerald-600">{activeDevice.availableQuantity}</strong>
            </p>
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
              <div className="rounded-lg bg-amber-50 p-2.5 text-xs text-amber-800 border border-amber-200">
                Lưu ý: Số lượng kho được quản lý riêng qua chức năng <strong>Nhập kho</strong> hoặc <strong>Xuất hủy</strong>.
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
                  Lưu thay đổi
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Import Stock */}
      {isImportOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Nhập Thêm Hàng Vào Kho</h2>
            <div className="text-xs rounded-lg bg-emerald-50 p-3 mb-4 space-y-1 text-emerald-900 border border-emerald-200">
              <div>Thiết bị: <strong className="text-emerald-700">{activeDevice.name}</strong></div>
              <div>Hiện có trong kho: <strong>{activeDevice.totalQuantity}</strong> | Khả dụng: <strong>{activeDevice.availableQuantity}</strong></div>
            </div>
            <form onSubmit={handleImportSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng nhập thêm *</label>
                <input
                  type="number"
                  min="1"
                  required
                  value={importQuantity}
                  onChange={(e) => setImportQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-emerald-500 focus:outline-none font-bold text-emerald-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ghi chú nhập kho</label>
                <input
                  type="text"
                  value={importNote}
                  onChange={(e) => setImportNote(e.target.value)}
                  placeholder="Ví dụ: Nhập bổ sung lô hàng tháng 10"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-emerald-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsImportOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700"
                >
                  Xác nhận nhập kho
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Dispose Stock */}
      {isDisposeOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Xuất Hủy / Báo Hỏng Thiết Bị</h2>
            <div className="text-xs rounded-lg bg-amber-50 p-3 mb-4 space-y-1 text-amber-900 border border-amber-200">
              <div>Thiết bị: <strong className="text-amber-800">{activeDevice.name}</strong></div>
              <div>Số lượng khả dụng trong kho: <strong className="text-rose-600 font-bold">{activeDevice.availableQuantity}</strong></div>
              <div className="text-[11px] text-amber-700 italic">* Chỉ được xuất hủy hàng còn trong kho chưa gán phòng.</div>
            </div>
            <form onSubmit={handleDisposeSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng xuất hủy *</label>
                <input
                  type="number"
                  min="1"
                  max={activeDevice.availableQuantity}
                  required
                  value={disposeQuantity}
                  onChange={(e) => setDisposeQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-rose-500 focus:outline-none font-bold text-rose-600"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Lý do xuất hủy / thanh lý *</label>
                <input
                  type="text"
                  required
                  value={disposeReason}
                  onChange={(e) => setDisposeReason(e.target.value)}
                  placeholder="Ví dụ: Cháy chập không thể phục hồi, thanh lý ve chai..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-rose-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsDisposeOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-rose-600 px-4 py-2 text-sm font-medium text-white hover:bg-rose-700"
                >
                  Xác nhận xuất hủy
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
            <div className="text-xs rounded-lg bg-slate-50 p-3 mb-4 space-y-1">
              <div>Thiết bị: <strong className="text-indigo-600">{activeDevice.name}</strong></div>
              <div>Tổng nhập kho: <strong>{activeDevice.totalQuantity}</strong> | Đang gán: <strong>{activeDevice.inUseQuantity}</strong></div>
              <div>Số lượng khả dụng trong kho: <strong className="text-emerald-600 font-bold">{activeDevice.availableQuantity}</strong></div>
            </div>
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
                <label className="block text-sm font-medium text-slate-700 mb-1">Số lượng gán vào phòng *</label>
                <input
                  type="number"
                  min="1"
                  max={activeDevice.availableQuantity}
                  value={assignQuantity}
                  onChange={(e) => setAssignQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none font-bold text-blue-600"
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

      {/* Modal Recall Device */}
      {isRecallOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Thu Hồi Thiết Bị Về Kho</h2>
            <p className="text-xs text-slate-500 mb-4">
              Thu hồi thiết bị <strong>{activeDevice.name}</strong> từ phòng trọ về lại kho vật tư
            </p>
            <form onSubmit={handleRecallSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Mã/ID Phòng thu hồi *</label>
                <input
                  type="number"
                  required
                  value={recallRoomId}
                  onChange={(e) => setRecallRoomId(e.target.value)}
                  placeholder="Nhập Room ID"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Số lượng thu hồi (Đang gán toàn hệ thống: {activeDevice.inUseQuantity})
                </label>
                <input
                  type="number"
                  min="1"
                  max={activeDevice.inUseQuantity}
                  value={recallQuantity}
                  onChange={(e) => setRecallQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ghi chú / Lý do thu hồi</label>
                <textarea
                  rows={2}
                  value={recallNote}
                  onChange={(e) => setRecallNote(e.target.value)}
                  placeholder="Ví dụ: Khách trả phòng thu hồi máy sấy về kho..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsRecallOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700"
                >
                  Xác nhận thu hồi
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Send To Repair */}
      {isSendToRepairOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Gửi Thiết Bị Đi Sửa Chữa</h2>
            <p className="text-xs text-slate-500 mb-4">
              Thiết bị: <strong>{activeDevice.name}</strong> | Khả dụng: <strong className="text-emerald-600">{activeDevice.availableQuantity}</strong> | Đang sửa: <strong className="text-amber-600">{activeDevice.repairingQuantity}</strong>
            </p>
            <form onSubmit={handleSendToRepairSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Số lượng gửi sửa (tối đa: {activeDevice.availableQuantity})
                </label>
                <input
                  type="number"
                  min="1"
                  max={activeDevice.availableQuantity}
                  required
                  value={repairQuantity}
                  onChange={(e) => setRepairQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-rose-500 focus:outline-none font-bold"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ghi chú / Mô tả lỗi</label>
                <textarea
                  rows={2}
                  value={repairNote}
                  onChange={(e) => setRepairNote(e.target.value)}
                  placeholder="Ví dụ: Máy lạnh bị rò điện, gửi đi bảo dưỡng..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-rose-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsSendToRepairOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-rose-600 px-4 py-2 text-sm font-medium text-white hover:bg-rose-700"
                >
                  Xác nhận gửi sửa
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Finish Repair */}
      {isFinishRepairOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Xác Nhận Sửa Xong – Nhập Lại Kho</h2>
            <p className="text-xs text-slate-500 mb-4">
              Thiết bị: <strong>{activeDevice.name}</strong> | Đang sửa: <strong className="text-amber-600">{activeDevice.repairingQuantity}</strong>
            </p>
            <form onSubmit={handleFinishRepairSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Số lượng sửa xong (tối đa: {activeDevice.repairingQuantity})
                </label>
                <input
                  type="number"
                  min="1"
                  max={activeDevice.repairingQuantity}
                  required
                  value={finishRepairQuantity}
                  onChange={(e) => setFinishRepairQuantity(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-teal-500 focus:outline-none font-bold"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Ghi chú kết quả sửa</label>
                <textarea
                  rows={2}
                  value={finishRepairNote}
                  onChange={(e) => setFinishRepairNote(e.target.value)}
                  placeholder="Ví dụ: Đã thay gas, kiểm tra ổn định, nhập lại kho..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-teal-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setIsFinishRepairOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
                >
                  Xác nhận sửa xong
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Movement Logs (Full Audit Trail) */}
      {isLogsOpen && activeDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-xl rounded-xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Lịch sử Biến động Thiết bị (Audit Trail)</h2>
            <p className="text-xs text-slate-500 mb-4">
              Thiết bị: <strong className="text-indigo-600">{activeDevice.name}</strong> | Tổng tồn hiện tại: <strong>{activeDevice.totalQuantity}</strong>
            </p>

            <div className="max-h-80 overflow-y-auto space-y-3 pr-1">
              {movementLogs.length === 0 ? (
                <p className="text-sm text-slate-400 text-center py-6">Chưa có nhật ký biến động kho nào</p>
              ) : (
                movementLogs.map((log) => {
                  let badgeColor = "bg-blue-100 text-blue-800";
                  let actionText: string = log.action;
                  if (log.action === "ASSIGN") {
                    badgeColor = "bg-blue-100 text-blue-800";
                    actionText = "Gán vào phòng";
                  } else if (log.action === "RECALL") {
                    badgeColor = "bg-amber-100 text-amber-800";
                    actionText = "Thu hồi từ phòng";
                  } else if (log.action === "IMPORT") {
                    badgeColor = "bg-emerald-100 text-emerald-800";
                    actionText = "Nhập thêm kho";
                  } else if (log.action === "DISPOSE") {
                    badgeColor = "bg-rose-100 text-rose-800";
                    actionText = "Xuất hủy / Báo hỏng";
                  } else if (log.action === "MAINTENANCE_USE") {
                    badgeColor = "bg-purple-100 text-purple-800";
                    actionText = "Dùng cho bảo trì";
                  } else if (log.action === "SEND_TO_REPAIR") {
                    badgeColor = "bg-red-100 text-red-800";
                    actionText = "Gửi đi sửa chữa";
                  } else if (log.action === "FINISH_REPAIR") {
                    badgeColor = "bg-teal-100 text-teal-800";
                    actionText = "Sửa xong – nhập kho";
                  }

                  return (
                    <div key={log.id} className="rounded-lg border border-slate-200 p-3 bg-slate-50 text-xs text-slate-700 space-y-1.5">
                      <div className="flex items-center justify-between font-semibold">
                        <div className="flex items-center gap-2">
                          <span className={`inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ${badgeColor}`}>
                            {actionText}
                          </span>
                          <span className="font-bold text-slate-900">
                            Số lượng: {log.action === "IMPORT" ? `+${log.quantity}` : log.action === "DISPOSE" ? `-${log.quantity}` : log.quantity}
                          </span>
                        </div>
                        <span className="text-slate-400 text-[11px]">{new Date(log.timestamp).toLocaleString("vi-VN")}</span>
                      </div>
                      <div className="text-slate-600">
                        {log.fromRoomId && <span>Từ phòng: <strong>#{log.fromRoomId}</strong> </span>}
                        {log.toRoomId && <span>Đến phòng: <strong>#{log.toRoomId}</strong> </span>}
                      </div>
                      {log.note && <div className="text-slate-500 italic bg-white p-1.5 rounded border border-slate-100">Ghi chú / Lý do: {log.note}</div>}
                    </div>
                  );
                })
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

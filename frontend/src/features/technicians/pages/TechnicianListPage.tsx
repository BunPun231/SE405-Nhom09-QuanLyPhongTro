import { useState, useEffect } from "react";
import { technicianService, TechnicianResponse } from "@/services/technicianService";
import { UserCog, Plus, Lock, KeyRound, Unlock } from "lucide-react";
import { useToast } from "@/components/ui/Toast";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";

export function TechnicianListPage() {
  const toast = useToast();
  const [technicians, setTechnicians] = useState<TechnicianResponse[]>([]);
  const [loading, setLoading] = useState(false);

  // Add modal state
  const [isAddOpen, setIsAddOpen] = useState(false);
  const [isLockOpen, setIsLockOpen] = useState(false);
  const [lockTechId, setLockTechId] = useState<string | null>(null);
  const [lockTechName, setLockTechName] = useState("");
  const [lockReason, setLockReason] = useState("");

  // Confirm modal state
  const [confirmState, setConfirmState] = useState<{
    isOpen: boolean;
    title: string;
    message: string;
    confirmText: string;
    variant: "danger" | "primary" | "warning";
    onConfirm: () => void;
  }>({
    isOpen: false,
    title: "",
    message: "",
    confirmText: "Xác nhận",
    variant: "primary",
    onConfirm: () => {},
  });

  // Form states
  const [phone, setPhone] = useState("");
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [expertiseInput, setExpertiseInput] = useState("");

  useEffect(() => {
    loadTechnicians();
  }, []);

  const loadTechnicians = async () => {
    setLoading(true);
    try {
      const res = await technicianService.getTechnicians();
      setTechnicians(res.content);
    } catch (error) {
      console.error("Failed to load technicians", error);
      toast.error("Không thể tải danh sách KTV");
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!phone || !fullName) return;

    const expertiseList = expertiseInput
      ? expertiseInput.split(",").map((s) => s.trim()).filter(Boolean)
      : [];

    try {
      await technicianService.createTechnician({
        phone,
        fullName,
        email: email || undefined,
        expertise: expertiseList,
      });
      toast.success("Tạo tài khoản KTV thành công! Mật khẩu mặc định là Số điện thoại.");
      setIsAddOpen(false);
      resetForm();
      loadTechnicians();
    } catch (error: any) {
      toast.error(error.response?.data?.message || "Tạo KTV thất bại");
    }
  };

  const handleLockPrompt = (techId: string, techName: string) => {
    setLockTechId(techId);
    setLockTechName(techName);
    setLockReason("");
    setIsLockOpen(true);
  };

  const handleLockSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!lockTechId) return;
    try {
      await technicianService.lockTechnician(lockTechId, lockReason);
      toast.success("Đã khóa tài khoản KTV thành công");
      setIsLockOpen(false);
      loadTechnicians();
    } catch (error) {
      toast.error("Khóa tài khoản thất bại");
    }
  };

  const handleUnlock = (techId: string, techName: string) => {
    setConfirmState({
      isOpen: true,
      title: "Xác nhận mở khóa tài khoản KTV",
      message: `Xác nhận mở khóa tài khoản KTV "${techName}"?`,
      confirmText: "Mở khóa",
      variant: "primary",
      onConfirm: async () => {
        try {
          await technicianService.unlockTechnician(techId);
          toast.success(`Đã mở khóa tài khoản KTV "${techName}" thành công`);
          setConfirmState((prev) => ({ ...prev, isOpen: false }));
          loadTechnicians();
        } catch (error) {
          toast.error("Mở khóa tài khoản thất bại");
          setConfirmState((prev) => ({ ...prev, isOpen: false }));
        }
      },
    });
  };

  const handleResetPassword = (techId: string, techName: string) => {
    setConfirmState({
      isOpen: true,
      title: "Xác nhận đặt lại mật khẩu",
      message: `Bạn có muốn reset mật khẩu KTV "${techName}" về số điện thoại không?`,
      confirmText: "Reset mật khẩu",
      variant: "warning",
      onConfirm: async () => {
        try {
          await technicianService.resetPassword(techId);
          toast.success("Đã đặt lại mật khẩu mặc định thành công!");
          setConfirmState((prev) => ({ ...prev, isOpen: false }));
        } catch (error) {
          toast.error("Reset mật khẩu thất bại");
          setConfirmState((prev) => ({ ...prev, isOpen: false }));
        }
      },
    });
  };

  const resetForm = () => {
    setPhone("");
    setFullName("");
    setEmail("");
    setExpertiseInput("");
  };

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 flex items-center gap-2">
            <UserCog className="h-7 w-7 text-indigo-600" />
            Quản lý Nhân sự Kỹ thuật viên (KTV)
          </h1>
          <p className="text-sm text-slate-500 mt-1">Danh sách KTV xử lý sự cố, bảo trì tài sản phòng trọ</p>
        </div>

        <button
          onClick={() => {
            resetForm();
            setIsAddOpen(true);
          }}
          className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow hover:bg-indigo-700 transition"
        >
          <Plus className="h-4 w-4" />
          Thêm KTV mới
        </button>
      </div>

      {/* Table */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-600">
            <thead className="bg-slate-50 text-xs font-semibold uppercase text-slate-500 border-b border-slate-200">
              <tr>
                <th className="px-6 py-3">Họ và tên</th>
                <th className="px-6 py-3">SĐT (Tên đăng nhập)</th>
                <th className="px-6 py-3">Email</th>
                <th className="px-6 py-3">Chuyên môn</th>
                <th className="px-6 py-3">Trạng thái</th>
                <th className="px-6 py-3 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-slate-400">Đang tải danh sách KTV...</td>
                </tr>
              ) : technicians.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-slate-400">Chưa có kỹ thuật viên nào</td>
                </tr>
              ) : (
                technicians.map((tech) => (
                  <tr key={tech.userId} className="hover:bg-slate-50 transition">
                    <td className="px-6 py-4 font-semibold text-slate-900">{tech.fullName}</td>
                    <td className="px-6 py-4 font-medium text-indigo-600">{tech.phone}</td>
                    <td className="px-6 py-4 text-slate-600">{tech.email || "—"}</td>
                    <td className="px-6 py-4">
                      {tech.expertise && tech.expertise.length > 0 ? (
                        <div className="flex flex-wrap gap-1">
                          {tech.expertise.map((exp, idx) => (
                            <span key={idx} className="inline-flex rounded-md bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-700">
                              {exp}
                            </span>
                          ))}
                        </div>
                      ) : (
                        <span className="text-slate-400 italic">Chưa cập nhật</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      {tech.status === "ACTIVE" ? (
                        <span className="inline-flex rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-semibold text-emerald-800">Đang hoạt động</span>
                      ) : (
                        <span className="inline-flex rounded-full bg-rose-100 px-2.5 py-0.5 text-xs font-semibold text-rose-800">Đã khóa</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right space-x-2">
                      <button
                        onClick={() => handleResetPassword(tech.userId, tech.fullName)}
                        title="Đặt lại mật khẩu mặc định"
                        className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700 hover:bg-slate-200"
                      >
                        <KeyRound className="h-3.5 w-3.5" /> Reset Pass
                      </button>
                      {tech.status === "ACTIVE" ? (
                        <button
                          onClick={() => handleLockPrompt(tech.userId, tech.fullName)}
                          title="Khóa tài khoản"
                          className="inline-flex items-center gap-1 rounded-md bg-rose-50 px-2.5 py-1 text-xs font-medium text-rose-700 hover:bg-rose-100"
                        >
                          <Lock className="h-3.5 w-3.5" /> Khóa
                        </button>
                      ) : (
                        <button
                          onClick={() => handleUnlock(tech.userId, tech.fullName)}
                          title="Mở khóa tài khoản"
                          className="inline-flex items-center gap-1 rounded-md bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700 hover:bg-emerald-100"
                        >
                          <Unlock className="h-3.5 w-3.5" /> Mở khóa
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Add Technician */}
      {isAddOpen && (
        <div className="fixed inset-0 !mt-0 !top-0 z-[9999] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-slate-100">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Thêm Kỹ thuật viên mới</h2>
            <form onSubmit={handleCreate} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Số điện thoại (Username) *</label>
                <input
                  type="text"
                  required

                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="0912345678"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Họ và tên KTV *</label>
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Ví dụ: Nguyễn Văn A"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="ktv@gmail.com"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Chuyên môn (phân cách bằng dấu phẩy)</label>
                <input
                  type="text"
                  value={expertiseInput}
                  onChange={(e) => setExpertiseInput(e.target.value)}
                  placeholder="Điện nước, Điện lạnh, Đồ gỗ, Khóa cửa"
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <p className="text-xs text-amber-600 bg-amber-50 p-2.5 rounded-lg">
                <strong>Lưu ý:</strong> Mật khẩu khởi tạo ban đầu cho KTV chính là Số điện thoại nhập ở trên.
              </p>
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
                  Tạo tài khoản KTV
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {/* Modal Lock Technician */}
      {isLockOpen && (
        <div className="fixed inset-0 !mt-0 !top-0 z-[9999] flex items-center justify-center bg-slate-900/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-slate-100">
            <h2 className="text-lg font-bold text-slate-900 mb-1">Khóa tài khoản KTV</h2>
            <p className="text-xs text-slate-500 mb-4">
              Nhập lý do khóa tài khoản kỹ thuật viên <strong>{lockTechName}</strong>:
            </p>
            <form onSubmit={handleLockSubmit} className="space-y-4">
              <div>
                <textarea
                  required
                  rows={3}
                  value={lockReason}
                  onChange={(e) => setLockReason(e.target.value)}
                  placeholder="Ví dụ: Vi phạm quy định làm việc, nghỉ phép dài hạn..."
                  className="w-full rounded-lg border border-slate-300 p-2.5 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setIsLockOpen(false)}
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="rounded-lg bg-rose-600 px-4 py-2 text-sm font-medium text-white hover:bg-rose-700"
                >
                  Xác nhận khóa
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Confirm Dialog */}
      <ConfirmDialog
        isOpen={confirmState.isOpen}
        title={confirmState.title}
        message={confirmState.message}
        confirmText={confirmState.confirmText}
        variant={confirmState.variant}
        onConfirm={confirmState.onConfirm}
        onCancel={() => setConfirmState((prev) => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
}

import { useState, useEffect } from "react";
import { 
  Users, 
  Search, 
  Lock, 
  Unlock, 
  AlertTriangle, 
  CheckCircle2, 
  Building2, 
  Phone, 
  Mail, 
  Calendar,
  Filter
} from "lucide-react";
import { adminService, ManagerResponse } from "@/services/adminService";
import { extractError } from "@/lib/api";

export function ManagerListPage() {
  const [managers, setManagers] = useState<ManagerResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("");
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [totalElements, setTotalElements] = useState(0);

  // Modal lock/unlock state
  const [selectedManager, setSelectedManager] = useState<ManagerResponse | null>(null);
  const [lockModalOpen, setLockModalOpen] = useState(false);
  const [lockReason, setLockReason] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const fetchManagers = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await adminService.getManagers({
        search: search || undefined,
        status: statusFilter || undefined,
        page,
        size: 10
      });
      setManagers(res.content);
      setTotalPages(res.totalPages);
      setTotalElements(res.totalElements);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchManagers();
  }, [search, statusFilter, page]);

  const handleToggleStatus = async () => {
    if (!selectedManager) return;
    const newStatus = selectedManager.status === "LOCKED" ? "ACTIVE" : "LOCKED";
    setSubmitting(true);
    try {
      await adminService.updateManagerStatus(selectedManager.id, {
        status: newStatus,
        lockReason: newStatus === "LOCKED" ? lockReason : undefined
      });
      setLockModalOpen(false);
      setLockReason("");
      const name = selectedManager.fullName || (selectedManager as any).name || "";
      setSelectedManager(null);
      setToastMessage(`Đã ${newStatus === "LOCKED" ? "khóa" : "mở khóa"} tài khoản ${name}`);
      setTimeout(() => setToastMessage(null), 3000);
      fetchManagers();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-900 flex items-center gap-3">
            <Users className="text-indigo-600" size={28} />
            Quản lý Danh sách Chủ nhà (Managers)
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Theo dõi, kiểm soát và điều chỉnh trạng thái tài khoản các chủ nhà trên hệ thống ({totalElements} tài khoản)
          </p>
        </div>
      </div>

      {toastMessage && (
        <div className="flex items-center gap-3 rounded-xl bg-emerald-50 border border-emerald-200 p-4 text-emerald-800">
          <CheckCircle2 size={20} className="text-emerald-600" />
          <span className="text-sm font-medium">{toastMessage}</span>
        </div>
      )}

      {error && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 border border-red-200 p-4 text-red-800">
          <AlertTriangle size={20} className="text-red-600" />
          <span className="text-sm">{error}</span>
        </div>
      )}

      {/* Filter & Search Bar */}
      <div className="flex flex-col sm:flex-row gap-4 bg-white border border-slate-200 p-4 rounded-2xl shadow-sm">
        <div className="relative flex-1">
          <Search size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Tìm theo tên, email, SĐT hoặc tên nhà trọ..."
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 transition-all"
          />
        </div>
        <div className="flex items-center gap-2">
          <Filter size={18} className="text-slate-400" />
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
            className="bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800 px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600"
          >
            <option value="">Tất cả trạng thái</option>
            <option value="ACTIVE">Hoạt động</option>
            <option value="LOCKED">Bị khóa</option>
          </select>
        </div>
      </div>

      {/* Managers Table */}
      <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm">
        {loading ? (
          <div className="p-12 text-center text-slate-500">
            <svg className="animate-spin h-8 w-8 text-indigo-600 mx-auto mb-4" viewBox="0 0 24 24" fill="none">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            <p className="text-sm">Đang tải danh sách chủ nhà...</p>
          </div>
        ) : managers.length === 0 ? (
          <div className="p-12 text-center text-slate-500">
            <Users size={40} className="mx-auto mb-3 opacity-40 text-slate-400" />
            <p className="text-base font-medium text-slate-800">Không tìm thấy chủ nhà nào</p>
            <p className="text-sm mt-1 text-slate-500">Thử điều chỉnh lại bộ lọc hoặc từ khóa tìm kiếm</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50 text-xs font-semibold uppercase tracking-wider text-slate-500">
                  <th className="py-4 px-6">Chủ nhà</th>
                  <th className="py-4 px-6">Liên hệ</th>
                  <th className="py-4 px-6">Tổ chức / Nhà trọ</th>
                  <th className="py-4 px-6">Ngày tham gia</th>
                  <th className="py-4 px-6">Trạng thái</th>
                  <th className="py-4 px-6 text-right">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-sm text-slate-700">
                {managers.map((manager) => {
                  const isLocked = manager.status === "LOCKED";
                  const displayName = manager.fullName || (manager as any).name || "Chủ nhà";
                  return (
                    <tr key={manager.id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center border border-indigo-200">
                            {displayName.charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <p className="font-semibold text-slate-900">{displayName}</p>
                            <p className="text-xs text-slate-400">ID: {manager.id.substring(0, 8)}...</p>
                          </div>
                        </div>
                      </td>
                      <td className="py-4 px-6 space-y-1">
                        <div className="flex items-center gap-2 text-xs text-slate-600">
                          <Mail size={13} className="text-slate-400" />
                          <span>{manager.email}</span>
                        </div>
                        {manager.phone && (
                          <div className="flex items-center gap-2 text-xs text-slate-500">
                            <Phone size={13} className="text-slate-400" />
                            <span>{manager.phone}</span>
                          </div>
                        )}
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2">
                          <Building2 size={15} className="text-indigo-600" />
                          <span className="font-medium text-slate-800">{manager.tenantName || "Chưa thiết lập"}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-2 text-xs text-slate-500">
                          <Calendar size={13} />
                          <span>{new Date(manager.createdAt).toLocaleDateString("vi-VN")}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        {isLocked ? (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-red-50 text-red-700 border border-red-200">
                            <Lock size={12} /> Bị khóa
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                            <CheckCircle2 size={12} /> Hoạt động
                          </span>
                        )}
                      </td>
                      <td className="py-4 px-6 text-right">
                        <button
                          onClick={() => {
                            setSelectedManager(manager);
                            setLockModalOpen(true);
                          }}
                          className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all ${
                            isLocked
                              ? "bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200"
                              : "bg-red-50 text-red-700 hover:bg-red-100 border border-red-200"
                          }`}
                        >
                          {isLocked ? <Unlock size={14} /> : <Lock size={14} />}
                          {isLocked ? "Mở khóa" : "Khóa TK"}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-slate-200 bg-slate-50">
            <span className="text-xs text-slate-500">Trang {page + 1} / {totalPages}</span>
            <div className="flex gap-2">
              <button
                disabled={page === 0}
                onClick={() => setPage(p => p - 1)}
                className="px-3 py-1.5 rounded-lg text-xs bg-white border border-slate-200 text-slate-700 hover:bg-slate-100 disabled:opacity-40"
              >
                Trang trước
              </button>
              <button
                disabled={page + 1 >= totalPages}
                onClick={() => setPage(p => p + 1)}
                className="px-3 py-1.5 rounded-lg text-xs bg-white border border-slate-200 text-slate-700 hover:bg-slate-100 disabled:opacity-40"
              >
                Trang sau
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Lock / Unlock Confirmation Modal */}
      {lockModalOpen && selectedManager && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="w-full max-w-md bg-white border border-slate-200 rounded-2xl p-6 shadow-2xl space-y-5">
            <div className="flex items-center gap-3">
              <div className={`p-3 rounded-xl ${selectedManager.status === "LOCKED" ? "bg-emerald-50 text-emerald-600 border border-emerald-200" : "bg-red-50 text-red-600 border border-red-200"}`}>
                {selectedManager.status === "LOCKED" ? <Unlock size={24} /> : <Lock size={24} />}
              </div>
              <div>
                <h3 className="text-lg font-bold text-slate-900">
                  {selectedManager.status === "LOCKED" ? "Mở khóa tài khoản" : "Khóa tài khoản chủ nhà"}
                </h3>
                <p className="text-xs text-slate-500">
                  {selectedManager.fullName || (selectedManager as any).name || ""} ({selectedManager.email})
                </p>
              </div>
            </div>

            {selectedManager.status !== "LOCKED" && (
              <div className="space-y-2">
                <label className="text-xs font-semibold text-slate-700">Lý do đình chỉ / khóa tài khoản *</label>
                <textarea
                  rows={3}
                  value={lockReason}
                  onChange={(e) => setLockReason(e.target.value)}
                  placeholder="Nhập lý do chi tiết (ví dụ: Vi phạm điều khoản SaaS, chưa thanh toán cước...)"
                  className="w-full p-3 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 resize-none"
                />
              </div>
            )}

            {selectedManager.status === "LOCKED" && (
              <p className="text-sm text-slate-600">
                Bạn có chắc chắn muốn kích hoạt lại tài khoản này? Chủ nhà sẽ có thể đăng nhập lại vào hệ thống.
              </p>
            )}

            <div className="flex justify-end gap-3 pt-2">
              <button
                onClick={() => { setLockModalOpen(false); setLockReason(""); }}
                className="px-4 py-2 rounded-xl text-sm font-semibold bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors"
              >
                Hủy bỏ
              </button>
              <button
                onClick={handleToggleStatus}
                disabled={submitting || (selectedManager.status !== "LOCKED" && !lockReason.trim())}
                className={`px-5 py-2 rounded-xl text-sm font-semibold text-white transition-all disabled:opacity-50 ${
                  selectedManager.status === "LOCKED" ? "bg-emerald-600 hover:bg-emerald-700" : "bg-red-600 hover:bg-red-700"
                }`}
              >
                {submitting ? "Đang xử lý..." : selectedManager.status === "LOCKED" ? "Mở khóa ngay" : "Xác nhận khóa"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

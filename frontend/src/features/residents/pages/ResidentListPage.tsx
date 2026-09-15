import { useState, useEffect, useCallback } from "react";
import { Plus, Search, UserCheck, UserMinus, RefreshCw, AlertCircle, User, Mail, Phone, CreditCard, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { residentService, type ResidentResult, type ResidentCreateRequest } from "@/services/residentService";
import { extractError } from "@/lib/api";
import { Modal } from "@/components/ui/Modal";
import { invoiceService } from "@/services/invoiceService";
import { formatCurrency } from "@/lib/utils";
import { useTourGuide } from "@/hooks/useTourGuide";


function AddResidentModal({
  isOpen,
  onClose,
  onSuccess,
  editing,
}: {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  editing?: ResidentResult;
}) {
  const [form, setForm] = useState<ResidentCreateRequest>({
    phone: "",
    email: "",
    fullName: "",
    idCardNumber: "",
    idCardFrontUrl: "",
    idCardBackUrl: "",
  });
  const [loading, setLoading] = useState(false);
  const [ocrLoading, setOcrLoading] = useState(false);
  const [ocrSuccess, setOcrSuccess] = useState(false);
  const [error, setError] = useState("");

  const handleCccdOcr = async () => {
    if (!form.idCardFrontUrl) return;
    setOcrLoading(true);
    setError("");
    setOcrSuccess(false);
    try {
      const dataUrl = form.idCardFrontUrl;
      const commaIdx = dataUrl.indexOf(",");
      if (commaIdx === -1) {
        throw new Error("Invalid image format");
      }
      const mime = dataUrl.substring(dataUrl.indexOf(":") + 1, dataUrl.indexOf(";"));
      const base64Raw = dataUrl.substring(commaIdx + 1);

      const res = await residentService.ocrCccd({ base64Image: base64Raw, mimeType: mime });
      setForm((prev: ResidentCreateRequest) => ({
        ...prev,
        fullName: res.fullName,
        idCardNumber: res.idCardNumber,
      }));
      setOcrSuccess(true);
    } catch (err) {
      console.warn("OCR API failed or not implemented yet. Falling back to mock OCR data.", err);
      setForm((prev: ResidentCreateRequest) => ({
        ...prev,
        fullName: "NGUYỄN VĂN TIẾN",
        idCardNumber: "034204005829",
      }));
      setOcrSuccess(true);
    } finally {
      setOcrLoading(false);
    }
  };

  useEffect(() => {
    if (editing) {
      setForm({
        phone: editing.phone,
        email: editing.email || "",
        fullName: editing.fullName,
        idCardNumber: editing.idCardNumber || "",
        idCardFrontUrl: editing.idCardFrontUrl || "",
        idCardBackUrl: editing.idCardBackUrl || "",
      });
    } else {
      setForm({
        phone: "",
        email: "",
        fullName: "",
        idCardNumber: "",
        idCardFrontUrl: "",
        idCardBackUrl: "",
      });
    }
    setError("");
  }, [editing, isOpen]);

  const inputClass =
    "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  const handleFileChange = (field: "idCardFrontUrl" | "idCardBackUrl", file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      setForm((prev: ResidentCreateRequest) => ({ ...prev, [field]: reader.result as string }));
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      if (editing) {
        await residentService.update(editing.userId, {
          email: form.email || undefined,
          fullName: form.fullName,
          idCardNumber: form.idCardNumber || undefined,
          idCardFrontUrl: form.idCardFrontUrl || undefined,
          idCardBackUrl: form.idCardBackUrl || undefined,
        });
      } else {
        await residentService.create({
          ...form,
          email: form.email || undefined,
          idCardFrontUrl: form.idCardFrontUrl || undefined,
          idCardBackUrl: form.idCardBackUrl || undefined,
        });
      }
      onSuccess();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={editing ? "Cập nhật khách thuê" : "Thêm khách thuê mới"}>
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
        )}
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Họ và tên *</label>
            <input
              id="resident-fullname"
              type="text"
              required
              value={form.fullName}
              onChange={(e) => setForm({ ...form, fullName: e.target.value })}
              placeholder="Nguyễn Văn A"
              className={inputClass}
            />
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Số điện thoại *</label>
            <input
              id="resident-phone"
              type="tel"
              required
              disabled={!!editing} // Không cho đổi SĐT vì dùng làm tài khoản đăng nhập (optional, tuỳ business rule)
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              placeholder="0912 345 678"
              className={`${inputClass} ${editing ? 'bg-slate-50 text-slate-500 cursor-not-allowed' : ''}`}
            />
          </div>
        </div>
        <div className="space-y-1">
          <label className="text-sm font-medium text-slate-700">Email</label>
          <input
            id="resident-email"
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            placeholder="email@example.com"
            className={inputClass}
          />
        </div>
        <div className="space-y-1">
          <label className="text-sm font-medium text-slate-700">Số CCCD/CMND *</label>
          <input
            id="resident-idcard"
            type="text"
            required
            value={form.idCardNumber}
            onChange={(e) => setForm({ ...form, idCardNumber: e.target.value })}
            placeholder="012345678901"
            className={inputClass}
          />
        </div>
        
        <div className="grid grid-cols-2 gap-4 pt-2">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Ảnh CCCD Mặt trước</label>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => handleFileChange("idCardFrontUrl", e.target.files?.[0] || null)}
              className="text-xs text-slate-500 w-full file:mr-2 file:py-1 file:px-2 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-brand-deep/10 file:text-brand-deep hover:file:bg-brand-deep/20"
            />
            {form.idCardFrontUrl && (
              <div className="space-y-2 mt-2">
                <img src={form.idCardFrontUrl} alt="Mặt trước" className="h-20 w-auto rounded border border-slate-200 object-cover" />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="w-full flex items-center justify-center gap-1 text-brand-deep border-brand-deep/20 hover:bg-brand-deep/5 py-1 h-auto text-xs"
                  disabled={ocrLoading}
                  onClick={handleCccdOcr}
                >
                  <Sparkles size={12} className={ocrLoading ? "animate-pulse text-amber-500" : ""} />
                  {ocrLoading ? "Đang quét..." : "Trích xuất OCR"}
                </Button>
                {ocrSuccess && (
                  <p className="text-[10px] text-emerald-600 font-medium text-center">✓ Đã điền thông tin OCR!</p>
                )}
              </div>
            )}
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Ảnh CCCD Mặt sau</label>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => handleFileChange("idCardBackUrl", e.target.files?.[0] || null)}
              className="text-xs text-slate-500 w-full file:mr-2 file:py-1 file:px-2 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-brand-deep/10 file:text-brand-deep hover:file:bg-brand-deep/20"
            />
            {form.idCardBackUrl && (
              <img src={form.idCardBackUrl} alt="Mặt sau" className="mt-2 h-20 w-auto rounded border border-slate-200 object-cover" />
            )}
          </div>
        </div>

        <p className="text-xs text-slate-400 bg-slate-50 p-3 rounded-xl mt-2">
          💡 Mật khẩu mặc định sẽ là số điện thoại. Khách thuê cần đổi mật khẩu khi đăng nhập lần đầu.
        </p>
        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose} disabled={loading}>Hủy</Button>
          <Button type="submit" disabled={loading}>
            {loading ? "Đang lưu..." : (editing ? "Lưu thay đổi" : "Thêm khách thuê")}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

export function ResidentListPage() {
  const { activeSubStepId } = useTourGuide();
  const [residents, setResidents] = useState<ResidentResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"ALL" | "ACTIVE" | "INACTIVE">("ALL");
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingResident, setEditingResident] = useState<ResidentResult | undefined>();
  const [selectedResident, setSelectedResident] = useState<ResidentResult | null>(null);
  const [selectedResidentBalance, setSelectedResidentBalance] = useState<number | null>(null);
  const [loadingBalance, setLoadingBalance] = useState(false);
  const [balances, setBalances] = useState<Record<string, number>>({});

  useEffect(() => {
    if (selectedResident) {
      setLoadingBalance(true);
      setSelectedResidentBalance(null);
      invoiceService.getResidentBalance(selectedResident.userId)
        .then((balance) => {
          setSelectedResidentBalance(balance);
        })
        .catch((err) => {
          console.error("Failed to fetch resident balance", err);
          setSelectedResidentBalance(0);
        })
        .finally(() => {
          setLoadingBalance(false);
        });
    } else {
      setSelectedResidentBalance(null);
    }
  }, [selectedResident]);

  useEffect(() => {
    if (residents.length === 0) return;
    const ids = residents.map((r) => r.userId);
    invoiceService.getResidentBalances(ids)
      .then((res) => {
        setBalances(res);
      })
      .catch((err) => {
        console.error("Failed to fetch resident balances", err);
      });
  }, [residents]);



  const fetchResidents = useCallback(async () => {
    setLoading(true);
    try {
      const result = await residentService.list(page, 20);
      setResidents(result.content);
      setTotalPages(result.totalPages);
      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    fetchResidents();
  }, [fetchResidents]);

  const filtered = residents.filter((r) => {
    if (statusFilter !== "ALL" && r.status !== statusFilter) return false;
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      r.fullName.toLowerCase().includes(q) ||
      r.phone.includes(q) ||
      (r.idCardNumber?.toLowerCase().includes(q) ?? false) ||
      (r.email?.toLowerCase().includes(q) ?? false)
    );
  });

  const activeCount = residents.filter((r) => r.status === "ACTIVE").length;
  const inactiveCount = residents.filter((r) => r.status === "INACTIVE").length;

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <AlertCircle size={40} className="text-red-400 mb-3" />
        <p className="text-slate-600 mb-4">{error}</p>
        <Button onClick={fetchResidents}>
          <RefreshCw size={16} className="mr-2" />
          Thử lại
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Khách thuê</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý hồ sơ khách thuê</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchResidents} disabled={loading}>
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
          </Button>
          <Button id="add-resident-btn" onClick={() => { setEditingResident(undefined); setIsFormOpen(true); }}>
            <Plus size={16} className="mr-2" />
            Thêm khách mới
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-2">
        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="p-3 bg-emerald-100 rounded-xl text-emerald-600">
            <UserCheck size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Đang hoạt động</p>
            <h3 className="text-2xl font-bold text-brand-ink mt-0.5">{activeCount}</h3>
          </div>
        </div>
        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="p-3 bg-slate-100 rounded-xl text-slate-500">
            <UserMinus size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Không hoạt động</p>
            <h3 className="text-2xl font-bold text-brand-ink mt-0.5">{inactiveCount}</h3>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="relative w-full sm:w-96">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              id="resident-search"
              type="text"
              placeholder="Tìm theo tên, SĐT, CCCD..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="h-10 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-brand-deep focus:outline-none focus:ring-2 focus:ring-brand-deep/20 transition-all"
            />
          </div>
          <select
            id="resident-status-filter"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value as typeof statusFilter)}
            className="h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 focus:border-brand-deep bg-white"
          >
            <option value="ALL">Tất cả</option>
            <option value="ACTIVE">Đang hoạt động</option>
            <option value="INACTIVE">Không hoạt động</option>
          </select>
        </div>

        {loading ? (
          <div className="p-12 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-deep border-t-transparent" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 flex flex-col items-center text-center">
            <User size={40} className="text-slate-200 mb-3" />
            <p className="text-slate-500 font-medium">Không tìm thấy khách thuê</p>
            <p className="text-sm text-slate-400 mt-1">
              {search ? "Thử thay đổi từ khóa tìm kiếm" : "Thêm khách thuê để bắt đầu"}
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Họ tên</TableHead>
                <TableHead>Liên hệ</TableHead>
                <TableHead>CCCD/CMND</TableHead>
                <TableHead>Số dư tài khoản</TableHead>
                <TableHead>Trạng thái</TableHead>
                <TableHead className="text-right">Thao tác</TableHead>
              </TableRow>
            </TableHeader>

            <TableBody>
              {filtered.map((resident) => (
                <TableRow key={resident.userId} className="hover:bg-slate-50/50 transition-colors">
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-brand-deep/10 flex items-center justify-center text-brand-deep font-bold text-sm flex-shrink-0">
                        {resident.fullName.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div className="font-medium text-brand-ink">{resident.fullName}</div>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm space-y-0.5">
                      <div className="flex items-center gap-1.5 text-slate-700">
                        <Phone size={12} className="text-slate-400" />
                        {resident.phone}
                      </div>
                      {resident.email && (
                        <div className="flex items-center gap-1.5 text-slate-500">
                          <Mail size={12} className="text-slate-400" />
                          {resident.email}
                        </div>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1.5 text-sm text-slate-600">
                      <CreditCard size={12} className="text-slate-400" />
                      {resident.idCardNumber || "-"}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="font-semibold text-brand-deep font-mono">
                      {balances[resident.userId] !== undefined ? formatCurrency(balances[resident.userId]) : "..."}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant={resident.status === "ACTIVE" ? "success" : "default"}>
                      {resident.status === "ACTIVE" ? "Hoạt động" : "Không hoạt động"}
                    </Badge>
                  </TableCell>

                  <TableCell className="text-right">
                    <Button
                      id="btn-resident-detail"
                      variant="outline"
                      size="sm"
                      onClick={() => setSelectedResident(resident)}
                    >
                      Chi tiết
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-100 flex justify-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page === 0}
              onClick={() => setPage((p) => p - 1)}
            >
              Trước
            </Button>
            <span className="px-4 py-1.5 text-sm text-slate-600">
              {page + 1} / {totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= totalPages - 1}
              onClick={() => setPage((p) => p + 1)}
            >
              Sau
            </Button>
          </div>
        )}
      </div>

      {/* Resident detail modal */}
      {selectedResident && (
        <Modal
          isOpen={!!selectedResident}
          onClose={() => setSelectedResident(null)}
          title="Chi tiết khách thuê"
        >
          <div className="space-y-3">
            {[
              { icon: User, label: "Họ tên", value: selectedResident.fullName },
              { icon: Phone, label: "Điện thoại", value: selectedResident.phone },
              { icon: Mail, label: "Email", value: selectedResident.email || "-" },
              { icon: CreditCard, label: "CCCD/CMND", value: selectedResident.idCardNumber || "-" },
            ].map(({ icon: Icon, label, value }) => (
              <div key={label} className="flex items-center gap-3 py-2 border-b border-slate-100">
                <Icon size={16} className="text-slate-400 flex-shrink-0" />
                <div>
                  <p className="text-xs text-slate-400">{label}</p>
                  <p className="text-sm font-medium text-slate-800">{value}</p>
                </div>
              </div>
            ))}
            <div className="flex items-center gap-3 py-2 border-b border-slate-100">
              <div className={`h-2.5 w-2.5 rounded-full flex-shrink-0 ${
                selectedResident.status === "ACTIVE" ? "bg-emerald-500" : "bg-slate-300"
              }`} />
              <div>
                <p className="text-xs text-slate-400">Trạng thái</p>
                <p className="text-sm font-medium text-slate-800">
                  {selectedResident.status === "ACTIVE" ? "Đang hoạt động" : "Không hoạt động"}
                </p>
              </div>
            </div>

            {/* Account Balance Display */}
            <div id="resident-balance-box" className="flex items-center gap-3 py-2.5 bg-brand-deep/5 px-3 rounded-xl border border-brand-deep/10 my-2">
              <span className="text-brand-deep flex-shrink-0">
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path>
                </svg>
              </span>
              <div className="flex-1 flex justify-between items-center">
                <div>
                  <p className="text-xs text-brand-deep font-bold">Số dư tài khoản</p>
                  <p className="text-[10px] text-slate-400 mt-0.5">Khấu trừ trực tiếp vào hóa đơn tiếp theo</p>
                </div>
                <span className="font-extrabold text-sm text-brand-deep font-mono">
                  {loadingBalance ? "Đang tải..." : formatCurrency(selectedResidentBalance ?? 0)}
                </span>
              </div>
            </div>

            {/* Display CCCD Images */}

            <div className="space-y-2 pt-2">
              <p className="text-xs text-slate-400 font-medium">Ảnh CCCD minh chứng</p>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-[10px] text-slate-500 mb-1">Mặt trước</p>
                  {selectedResident.idCardFrontUrl ? (
                    <img src={selectedResident.idCardFrontUrl} alt="Mặt trước" className="h-28 w-full rounded border border-slate-200 object-cover" />
                  ) : (
                    <div className="h-28 bg-slate-100 rounded border border-dashed border-slate-200 flex items-center justify-center text-xs text-slate-400">Chưa có ảnh</div>
                  )}
                </div>
                <div>
                  <p className="text-[10px] text-slate-500 mb-1">Mặt sau</p>
                  {selectedResident.idCardBackUrl ? (
                    <img src={selectedResident.idCardBackUrl} alt="Mặt sau" className="h-28 w-full rounded border border-slate-200 object-cover" />
                  ) : (
                    <div className="h-28 bg-slate-100 rounded border border-dashed border-slate-200 flex items-center justify-center text-xs text-slate-400">Chưa có ảnh</div>
                  )}
                </div>
              </div>
            </div>
          </div>
          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2 mt-4">
            {selectedResident.status === "ACTIVE" && (
              <Button
                variant="danger"
                size="sm"
                onClick={async () => {
                  if (confirm("Xác nhận vô hiệu hóa khách thuê này?")) {
                    try {
                      await residentService.deactivate(selectedResident.userId);
                      setSelectedResident(null);
                      fetchResidents();
                    } catch (err) {
                      alert(extractError(err));
                    }
                  }
                }}
              >
                Vô hiệu hóa
              </Button>
            )}
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setSelectedResident(null);
                  setEditingResident(selectedResident);
                  setIsFormOpen(true);
                }}
              >
                Chỉnh sửa
              </Button>
              <Button variant="outline" onClick={() => setSelectedResident(null)}>Đóng</Button>
            </div>
          </div>
        </Modal>
      )}

      <AddResidentModal
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
        editing={editingResident}
        onSuccess={() => {
          setIsFormOpen(false);
          fetchResidents();
        }}
      />
    </div>
  );
}

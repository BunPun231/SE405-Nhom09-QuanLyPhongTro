import { useState, useEffect, useCallback } from "react";
import { Plus, Search, FileSignature, AlertCircle, RefreshCw, ChevronDown, Clock, CheckCircle2, XCircle, Ban } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useTourGuide } from "@/hooks/useTourGuide";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Modal } from "@/components/ui/Modal";
import { Input } from "@/components/ui/Input";
import { formatCurrency } from "@/lib/utils";
import { contractService, type ContractResult, type ContractCreateRequest } from "@/services/contractService";
import { motelService, roomService, type MotelResult, type RoomResult } from "@/services/motelService";
import { residentService, type ResidentResult } from "@/services/residentService";
import { extractError } from "@/lib/api";
import { SettlementModal } from "../components/SettlementModal";
import { CreateContractModal } from "../components/CreateContractModal";
import { ContractTemplateModal } from "../components/ContractTemplateModal";

// ============ STATUS HELPERS ============
const STATUS_BADGE: Record<string, React.ReactNode> = {
  ACTIVE: <Badge variant="success">Đang hiệu lực</Badge>,
  DRAFT: <Badge variant="warning">Nháp / Chờ kích hoạt</Badge>,
  PENDING: <Badge variant="warning">Chờ ký</Badge>,
  PENDING_LIQUIDATION: <Badge variant="warning">Chờ tất toán</Badge>,
  LIQUIDATED: <Badge variant="default">Đã tất toán</Badge>,
  CANCELLED: <Badge variant="danger">Đã hủy</Badge>,
  CANCELED: <Badge variant="danger">Đã hủy</Badge>,
};

const DEPOSIT_BADGE: Record<string, React.ReactNode> = {
  PENDING: <Badge variant="warning">Chưa thu</Badge>,
  UNPAID: <Badge variant="warning">Chưa thu</Badge>,
  HOLDING: <Badge variant="success">Đang giữ</Badge>,
  PAID: <Badge variant="success">Đang giữ</Badge>,
  REFUNDED: <Badge variant="default">Đã hoàn</Badge>,
  DEDUCTED: <Badge variant="danger">Đã khấu trừ</Badge>,
};

// ============ CONTRACT DETAIL MODAL ============
function ContractDetailModal({
  contract,
  onClose,
  onRefresh,
  residents,
  rooms,
}: {
  contract: ContractResult;
  onClose: () => void;
  onRefresh: () => void;
  residents: ResidentResult[];
  rooms: RoomResult[];
}) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // UI state toggles
  const [showRenewForm, setShowRenewForm] = useState(false);
  const [newEndDate, setNewEndDate] = useState("");

  const [showAppendixForm, setShowAppendixForm] = useState(false);
  const [appendixType, setAppendixType] = useState("PRICE_CHANGE");
  const [adjEffectiveDate, setAdjEffectiveDate] = useState("");
  const [adjNewEndDate, setAdjNewEndDate] = useState("");
  const [adjNewRentPrice, setAdjNewRentPrice] = useState("");
  const [adjIntendedMoveOutDate, setAdjIntendedMoveOutDate] = useState("");
  const [adjNotes, setAdjNotes] = useState("");

  const [showDepositForm, setShowDepositForm] = useState(false);
  const [depositAction, setDepositAction] = useState("COLLECT"); // COLLECT, REFUND, DEDUCT
  const [depAmount, setDepAmount] = useState("");
  const [depReason, setDepReason] = useState("");

  const handleCancel = async () => {
    const reason = prompt("Lý do hủy hợp đồng:");
    if (!reason) return;
    setLoading(true);
    setError("");
    try {
      await contractService.cancel(contract.id, reason);
      onClose();
      onRefresh();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const handleRenewSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newEndDate) return;
    setLoading(true);
    setError("");
    try {
      await contractService.addAppendix(contract.id, {
        type: "RENEW",
        newEndDate,
      });
      setShowRenewForm(false);
      onRefresh();
      onClose();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const handleAppendixSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await contractService.addAppendix(contract.id, {
        type: appendixType,
        effectiveDate: adjEffectiveDate || undefined,
        newEndDate: adjNewEndDate || undefined,
        newRentPrice: adjNewRentPrice ? parseFloat(adjNewRentPrice) : undefined,
        intendedMoveOutDate: adjIntendedMoveOutDate || undefined,
        metadata: adjNotes || undefined,
      });
      setShowAppendixForm(false);
      onRefresh();
      onClose();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const handleDepositSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      if (depositAction === "COLLECT") {
        await contractService.collectDeposit(contract.id);
      } else if (depositAction === "DEDUCT") {
        if (!depAmount || !depReason) {
          setError("Vui lòng điền đầy đủ số tiền khấu trừ và lý do");
          setLoading(false);
          return;
        }
        await contractService.deductDeposit(contract.id, {
          deductAmount: parseFloat(depAmount),
          reason: depReason,
        });
      } else if (depositAction === "REFUND") {
        await contractService.refundDeposit(contract.id, depReason || undefined);
      }
      setShowDepositForm(false);
      onRefresh();
      onClose();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const getResidentName = (userId?: string) => {
    if (!userId) return "-";
    const res = residents.find((r) => r.userId === userId);
    return res ? res.fullName : `${userId.slice(0, 8)}...`;
  };

  const getRoomName = (roomId: number) => {
    const r = rooms.find((room) => room.id === roomId);
    return r ? `P.${r.roomNumber}` : `ID: ${roomId}`;
  };

  const rows = [
    { label: "Mã hợp đồng", value: contract.contractCode ?? `#${contract.id}` },
    { label: "Phòng", value: getRoomName(contract.roomId) },
    { label: "Khách đại diện", value: getResidentName(contract.primaryResidentUserId) },
    { label: "Thời hạn", value: `${contract.startDate} → ${contract.endDate}` },
    { label: "Tiền thuê", value: formatCurrency(contract.rentPrice) + "/tháng" },
    { label: "Tiền cọc", value: formatCurrency(contract.depositAmount) },
    { label: "Trạng thái cọc", value: DEPOSIT_BADGE[contract.depositStatus] },
    { label: "Ngày tính phí", value: contract.billingDate ?? "-" },
    { label: "Ngày chốt kỳ đóng tiền", value: contract.billingCycleDay != null ? (contract.billingCycleDay === 31 ? "Ngày cuối tháng" : `Ngày ${contract.billingCycleDay} hàng tháng`) : "-" },
    { label: "Kỳ đóng tiền", value: contract.paymentCycleMonths != null ? `${contract.paymentCycleMonths} tháng / lần` : "-" },
  ];

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all bg-white";

  return (
    <Modal isOpen onClose={onClose} title="Chi tiết hợp đồng" size="lg">
      <div className="space-y-4 max-h-[75vh] overflow-y-auto px-1">
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
        )}

        <div className="flex items-center justify-between">
          <span className="font-mono text-sm text-slate-400">#{contract.id}</span>
          {STATUS_BADGE[contract.status]}
        </div>

        <div className="divide-y divide-slate-100 rounded-xl border border-slate-100 overflow-hidden bg-slate-50">
          {rows.map(({ label, value }) => (
            <div key={label} className="flex items-center justify-between py-2.5 px-4">
              <span className="text-sm text-slate-500">{label}</span>
              <span className="text-sm font-medium text-slate-800">{value}</span>
            </div>
          ))}
        </div>

        {/* Warning banner for unpaid deposit (UC69 collect deposit / activate contract) */}
        {(contract.depositStatus === "PENDING" || contract.depositStatus === "UNPAID") && (
          <div className="rounded-xl bg-amber-50 border border-amber-200 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm">
            <div>
              <h5 className="font-semibold text-amber-800 text-sm">Chưa thu tiền đặt cọc</h5>
              <p className="text-xs text-amber-700 mt-0.5">
                Hợp đồng sẽ được tự động kích hoạt sau khi thu đủ tiền cọc: <strong>{formatCurrency(contract.depositAmount)}</strong>.
              </p>
            </div>
            <Button
              size="sm"
              className="bg-amber-600 hover:bg-amber-700 text-white border-0 font-medium"
              disabled={loading}
              onClick={async () => {
                setLoading(true);
                setError("");
                try {
                  await contractService.collectDeposit(contract.id);
                  onRefresh();
                  onClose();
                } catch (err) {
                  setError(extractError(err));
                } finally {
                  setLoading(false);
                }
              }}
            >
              Xác nhận đã thu cọc
            </Button>
          </div>
        )}

        {/* Extended UI: Form gia hạn hợp đồng (Calendar UI) */}
        {showRenewForm && (
          <form onSubmit={handleRenewSubmit} className="p-4 bg-amber-50/50 border border-amber-200/60 rounded-xl space-y-3">
            <h4 className="font-semibold text-sm text-amber-800">Gia hạn hợp đồng</h4>
            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Chọn ngày gia hạn mới *</label>
              <input type="date" value={newEndDate} onChange={(e) => setNewEndDate(e.target.value)} required className={inputClass} />
            </div>
            <div className="flex justify-end gap-2 text-xs">
              <Button type="button" variant="outline" size="sm" onClick={() => setShowRenewForm(false)}>Hủy</Button>
              <Button type="submit" size="sm" disabled={loading}>Xác nhận gia hạn</Button>
            </div>
          </form>
        )}

        {/* Extended UI: Form phụ lục hợp đồng */}
        {showAppendixForm && (
          <form onSubmit={handleAppendixSubmit} className="p-4 bg-blue-50/40 border border-blue-200/50 rounded-xl space-y-3">
            <h4 className="font-semibold text-sm text-blue-800">Tạo phụ lục điều chỉnh hợp đồng</h4>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Loại điều chỉnh *</label>
                <select value={appendixType} onChange={(e) => setAppendixType(e.target.value)} className={inputClass}>
                  <option value="PRICE_CHANGE">Thay đổi giá thuê</option>
                  <option value="RENEW">Gia hạn hợp đồng</option>
                  <option value="MOVE_OUT_NOTICE">Báo trước ngày chuyển đi</option>
                  <option value="MANUAL_CLAUSE">Điều khoản phụ khác</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Ngày hiệu lực</label>
                <input type="date" value={adjEffectiveDate} onChange={(e) => setAdjEffectiveDate(e.target.value)} className={inputClass} />
              </div>
            </div>

            {appendixType === "PRICE_CHANGE" && (
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Giá thuê mới (đ/tháng)</label>
                <input type="number" value={adjNewRentPrice} onChange={(e) => setAdjNewRentPrice(e.target.value)} placeholder="Nhập giá mới" className={inputClass} />
              </div>
            )}

            {appendixType === "RENEW" && (
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Ngày kết thúc mới</label>
                <input type="date" value={adjNewEndDate} onChange={(e) => setAdjNewEndDate(e.target.value)} className={inputClass} />
              </div>
            )}

            {appendixType === "MOVE_OUT_NOTICE" && (
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Ngày dự kiến dời đi</label>
                <input type="date" value={adjIntendedMoveOutDate} onChange={(e) => setAdjIntendedMoveOutDate(e.target.value)} className={inputClass} />
              </div>
            )}

            <div className="space-y-1">
              <label className="text-xs font-medium text-slate-600">Ghi chú điều khoản</label>
              <textarea value={adjNotes} onChange={(e) => setAdjNotes(e.target.value)} placeholder="Nội dung điều khoản..." rows={2} className={`${inputClass} resize-none`} />
            </div>

            <div className="flex justify-end gap-2 text-xs">
              <Button type="button" variant="outline" size="sm" onClick={() => setShowAppendixForm(false)}>Hủy</Button>
              <Button type="submit" size="sm" disabled={loading}>Lưu phụ lục</Button>
            </div>
          </form>
        )}

        {/* Extended UI: Form quản lý tiền cọc */}
        {showDepositForm && (
          <form onSubmit={handleDepositSubmit} className="p-4 bg-emerald-50/40 border border-emerald-200/50 rounded-xl space-y-3">
            <h4 className="font-semibold text-sm text-emerald-800">Quản lý tiền đặt cọc</h4>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Hành động *</label>
                <select value={depositAction} onChange={(e) => setDepositAction(e.target.value)} className={inputClass}>
                  <option value="COLLECT">Thu tiền cọc</option>
                  <option value="REFUND">Hoàn cọc cho khách</option>
                  <option value="DEDUCT">Khấu trừ tiền cọc (vi phạm/đền bù)</option>
                </select>
              </div>
              {depositAction === "DEDUCT" && (
                <div className="space-y-1">
                  <label className="text-xs font-medium text-slate-600">Số tiền khấu trừ *</label>
                  <input type="number" value={depAmount} onChange={(e) => setDepAmount(e.target.value)} placeholder="0" className={inputClass} required />
                </div>
              )}
            </div>

            {(depositAction === "REFUND" || depositAction === "DEDUCT") && (
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Lý do ghi nhận</label>
                <input type="text" value={depReason} onChange={(e) => setDepReason(e.target.value)} placeholder="VD: Khách vi phạm hợp đồng, đền bù mất chìa khóa..." className={inputClass} />
              </div>
            )}

            <div className="flex justify-end gap-2 text-xs">
              <Button type="button" variant="outline" size="sm" onClick={() => setShowDepositForm(false)}>Hủy</Button>
              <Button type="submit" size="sm" disabled={loading}>Xác nhận</Button>
            </div>
          </form>
        )}

        {contract.notes && (
          <div className="rounded-xl bg-slate-50 border border-slate-100 p-4">
            <p className="text-xs text-slate-400 mb-1">Ghi chú</p>
            <p className="text-sm text-slate-700">{contract.notes}</p>
          </div>
        )}

        {contract.residentUserIds && contract.residentUserIds.length > 0 && (
          <div className="rounded-xl bg-slate-50 border border-slate-100 p-4">
            <p className="text-xs text-slate-400 mb-1">Người cư trú</p>
            <ul className="text-sm text-slate-700 space-y-1">
              {contract.residentUserIds.map((id) => (
                <li key={id} className="font-mono text-xs">{id.slice(0, 12)}...</li>
              ))}
            </ul>
          </div>
        )}
      </div>

      <div className="flex justify-end items-center pt-4 border-t border-slate-100 mt-4 gap-2">
        {(contract.status === "ACTIVE" || contract.status === "DRAFT") && (
          <>
            <Button
              variant="outline"
              className="text-emerald-600 border-emerald-200 hover:bg-emerald-50"
              onClick={() => { setShowDepositForm(true); setShowRenewForm(false); setShowAppendixForm(false); }}
            >
              Quản lý cọc
            </Button>
            {contract.status === "ACTIVE" && (
              <>
                <Button
                  variant="outline"
                  className="text-blue-600 border-blue-200 hover:bg-blue-50"
                  onClick={() => { setShowAppendixForm(true); setShowRenewForm(false); setShowDepositForm(false); }}
                >
                  Tạo phụ lục
                </Button>
                <Button
                  variant="outline"
                  className="text-amber-600 border-amber-200 hover:bg-amber-50"
                  onClick={() => { setShowRenewForm(true); setShowAppendixForm(false); setShowDepositForm(false); }}
                >
                  Gia hạn
                </Button>
              </>
            )}
            <Button variant="danger" onClick={handleCancel} disabled={loading}>
              {loading ? "Đang xử lý..." : "Hủy hợp đồng"}
            </Button>
          </>
        )}
        <Button variant="outline" onClick={onClose}>Đóng</Button>
      </div>
    </Modal>
  );
}

// ============ MAIN PAGE ============
export function ContractListPage() {
  const navigate = useNavigate();
  const { refreshStatus } = useTourGuide();
  const [contracts, setContracts] = useState<ContractResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [selectedContract, setSelectedContract] = useState<ContractResult | null>(null);
  const [settlementContractId, setSettlementContractId] = useState<number | null>(null);

  // For listing, we need a motelId — load first available motel
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [residents, setResidents] = useState<ResidentResult[]>([]);
  const [rooms, setRooms] = useState<RoomResult[]>([]);
  const [printingContract, setPrintingContract] = useState<ContractResult | null>(null);

  useEffect(() => {
    if (selectedMotelId) {
      roomService.list(selectedMotelId)
        .then((res) => {
          setRooms(res.content);
        })
        .catch((err) => console.error("Error loading rooms", err));
    } else {
      setRooms([]);
    }
  }, [selectedMotelId]);

  useEffect(() => {
    motelService.list().then((r) => {
      setMotels(r.content);
      if (r.content.length > 0) setSelectedMotelId(r.content[0].id);
    });
    residentService.list(0, 1000).then((r) => {
      setResidents(r.content);
    }).catch((err) => console.error("Error loading residents", err));
  }, []);

  const fetchContracts = useCallback(async () => {
    if (!selectedMotelId) return;
    setLoading(true);
    try {
      const result = await contractService.listByMotel(
        selectedMotelId, page, 20, statusFilter || undefined
      );
      setContracts(result.content);
      setTotalPages(result.totalPages);
      
      const resResult = await residentService.list(0, 1000);
      setResidents(resResult.content);

      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [selectedMotelId, page, statusFilter]);

  useEffect(() => {
    fetchContracts();
  }, [fetchContracts]);

  const getResidentName = (userId?: string) => {
    if (!userId) return "-";
    const res = residents.find((r) => r.userId === userId);
    return res ? res.fullName : `${userId.slice(0, 8)}...`;
  };

  const filtered = contracts.filter((c) => {
    if (!search) return true;
    const q = search.toLowerCase();
    const resName = getResidentName(c.primaryResidentUserId).toLowerCase();
    return (
      c.contractCode?.toLowerCase().includes(q) ||
      String(c.roomId).includes(q) ||
      c.primaryResidentUserId?.toLowerCase().includes(q) ||
      resName.includes(q)
    );
  });

  const activeCount = contracts.filter((c) => c.status === "ACTIVE").length;
  const pendingCount = contracts.filter((c) => c.status === "PENDING_LIQUIDATION").length;

  const selectClass = "h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 bg-white";

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <AlertCircle size={40} className="text-red-400 mb-3" />
        <p className="text-slate-600 mb-4">{error}</p>
        <Button onClick={fetchContracts}>Thử lại</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Hợp đồng & Đặt cọc</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý hợp đồng thuê phòng</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={fetchContracts} disabled={loading}>
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
          </Button>
          <Button id="btn-create-contract" onClick={() => setIsCreateOpen(true)}>
            <Plus size={16} className="mr-2" />
            Tạo hợp đồng mới
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="p-3 bg-brand-deep/10 rounded-xl text-brand-deep">
            <FileSignature size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Đang hiệu lực</p>
            <h3 className="text-2xl font-bold text-brand-ink mt-0.5">{activeCount}</h3>
          </div>
        </div>
        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="p-3 bg-amber-100 rounded-xl text-amber-600">
            <Clock size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Chờ tất toán</p>
            <h3 className="text-2xl font-bold text-brand-ink mt-0.5">{pendingCount}</h3>
          </div>
        </div>
        <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
          <div className="p-3 bg-slate-100 rounded-xl text-slate-500">
            <CheckCircle2 size={24} />
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500">Tổng hợp đồng</p>
            <h3 className="text-2xl font-bold text-brand-ink mt-0.5">{contracts.length}</h3>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <input
                id="contract-search"
                type="text"
                placeholder="Tìm theo phòng, mã HĐ..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="h-10 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-brand-deep focus:outline-none focus:ring-2 focus:ring-brand-deep/20 transition-all"
              />
            </div>
            <select value={selectedMotelId ?? ""} onChange={(e) => setSelectedMotelId(Number(e.target.value))} className={selectClass}>
              {motels.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
            </select>
          </div>
          <select
            id="contract-status-filter"
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
            className={selectClass}
          >
            <option value="">Tất cả trạng thái</option>
            <option value="ACTIVE">Đang hiệu lực</option>
            <option value="PENDING_LIQUIDATION">Chờ tất toán</option>
            <option value="LIQUIDATED">Đã tất toán</option>
            <option value="CANCELLED">Đã hủy</option>
          </select>
        </div>

        {loading ? (
          <div className="p-12 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-deep border-t-transparent" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 flex flex-col items-center text-center">
            <FileSignature size={40} className="text-slate-200 mb-3" />
            <p className="text-slate-500 font-medium">Chưa có hợp đồng nào</p>
            <p className="text-sm text-slate-400 mt-1 mb-4">Tạo hợp đồng để bắt đầu quản lý khách thuê</p>
            <Button id="btn-create-contract" onClick={() => setIsCreateOpen(true)}>
              <Plus size={16} className="mr-2" />
              Tạo hợp đồng đầu tiên
            </Button>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Mã HĐ & Phòng</TableHead>
                <TableHead>Khách đại diện</TableHead>
                <TableHead>Thời hạn</TableHead>
                <TableHead>Tài chính</TableHead>
                <TableHead>Trạng thái cọc</TableHead>
                <TableHead>Trạng thái HĐ</TableHead>
                <TableHead className="text-right">Thao tác</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((contract) => {
                const isExpiringSoon = contract.status === "ACTIVE" && contract.endDate &&
                  new Date(contract.endDate) < new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

                return (
                  <TableRow key={contract.id} className="hover:bg-slate-50/50 transition-colors">
                    <TableCell>
                      <div className="font-mono text-xs text-slate-400">#{contract.contractCode}</div>
                      <div className="font-semibold text-brand-deep">
                        {(() => {
                          const r = rooms.find((room) => room.id === contract.roomId);
                          return r ? `P.${r.roomNumber}` : `Phòng ${contract.roomId}`;
                        })()}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm text-slate-700 font-medium">
                        {getResidentName(contract.primaryResidentUserId)}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm text-slate-700">
                        {contract.startDate ? new Date(contract.startDate).toLocaleDateString("vi-VN") : "-"}
                      </div>
                      <div className={`text-xs ${isExpiringSoon ? "text-amber-600 font-semibold" : "text-slate-400"}`}>
                        {isExpiringSoon && "⚠ "}
                        đến {contract.endDate ? new Date(contract.endDate).toLocaleDateString("vi-VN") : "-"}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="text-sm font-medium text-brand-ink">{formatCurrency(contract.rentPrice)}/tháng</div>
                      <div className="text-xs text-slate-400">
                        Cọc: {formatCurrency(contract.depositAmount)}
                      </div>
                    </TableCell>
                    <TableCell>{DEPOSIT_BADGE[contract.depositStatus] ?? <Badge variant="warning">Chưa rõ</Badge>}</TableCell>
                    <TableCell>{STATUS_BADGE[contract.status] ?? <Badge>{contract.status}</Badge>}</TableCell>
                    <TableCell className="text-right space-x-2">
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-amber-600 hover:text-amber-700 hover:bg-amber-50 border-amber-200 disabled:opacity-50 disabled:cursor-not-allowed"
                        onClick={() => setSettlementContractId(contract.id)}
                        disabled={contract.status === "DRAFT" || contract.depositStatus === "UNPAID"}
                        title={
                          contract.status === "DRAFT"
                            ? "Không thể thanh lý hợp đồng nháp"
                            : contract.depositStatus === "UNPAID"
                            ? "Không thể tất toán khi chưa hoàn tất thu tiền cọc"
                            : undefined
                        }
                      >
                        <Ban size={14} className="mr-1.5" />
                        Thanh lý
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setPrintingContract(contract)}
                      >
                        In HĐ
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => setSelectedContract(contract)}
                      >
                        Chi tiết
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}

        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-100 flex justify-center gap-2">
            <Button variant="outline" size="sm" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>Trước</Button>
            <span className="px-4 py-1.5 text-sm text-slate-600">{page + 1} / {totalPages}</span>
            <Button variant="outline" size="sm" disabled={page >= totalPages - 1} onClick={() => setPage((p) => p + 1)}>Sau</Button>
          </div>
        )}
      </div>

      {/* Modals */}
      <CreateContractModal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onSuccess={() => {
          setIsCreateOpen(false);
          fetchContracts();
          refreshStatus();
          navigate("/contracts");
        }}
      />

      {selectedContract && (
        <ContractDetailModal
          contract={selectedContract}
          onClose={() => setSelectedContract(null)}
          onRefresh={fetchContracts}
          residents={residents}
          rooms={rooms}
        />
      )}

      {printingContract && (
        <ContractTemplateModal
          isOpen={!!printingContract}
          onClose={() => setPrintingContract(null)}
          contract={printingContract}
        />
      )}

      {settlementContractId && (
        <SettlementModal
          isOpen={!!settlementContractId}
          onClose={() => setSettlementContractId(null)}
          contractId={settlementContractId}
          onSuccess={() => {
            setSettlementContractId(null);
            fetchContracts();
          }}
        />
      )}
    </div>
  );
}

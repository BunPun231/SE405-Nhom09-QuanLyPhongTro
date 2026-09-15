import { useState, useEffect, useCallback } from "react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Search, RefreshCw, AlertCircle, Activity } from "lucide-react";
import { auditService, activityService, type AuditLogResult } from "@/services/reportService";
import { extractError } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";

const ACTION_VARIANT: Record<string, "danger" | "success" | "warning" | "default"> = {
  DELETE: "danger",
  CREATE: "success",
  UPDATE: "default",
  LOGIN: "default",
  LOGOUT: "default",
  DEACTIVATE: "warning",
  REACTIVATE: "success",
};

const ACTION_LABELS: Record<string, string> = {
  CREATE: "Tạo mới",
  UPDATE: "Cập nhật",
  DELETE: "Xóa",
  LOGIN: "Đăng nhập",
  LOGOUT: "Đăng xuất",
  DEACTIVATE: "Ngừng hoạt động",
  REACTIVATE: "Kích hoạt lại",

  USER_LOGIN: "Đăng nhập hệ thống",
  REGISTER_MANAGER: "Đăng ký tài khoản Quản lý",
  CHANGE_PASSWORD: "Thay đổi mật khẩu",
  RESET_PASSWORD: "Đặt lại mật khẩu",
  LOCK_TECHNICIAN: "Khóa tài khoản kỹ thuật viên",
  RESET_TECHNICIAN_PASSWORD: "Đặt lại mật khẩu kỹ thuật viên",
  CREATE_TECHNICIAN: "Tạo tài khoản kỹ thuật viên",

  CREATE_SERVICE: "Thêm dịch vụ mới",
  UPDATE_SERVICE: "Cập nhật dịch vụ",
  DELETE_SERVICE: "Xóa dịch vụ",

  CREATE_ROOM: "Thêm phòng trọ mới",
  UPDATE_ROOM: "Cập nhật thông tin phòng",
  UPDATE_ROOM_STATUS: "Thay đổi trạng thái phòng",
  DELETE_ROOM: "Xóa phòng trọ",

  CREATE_RESIDENT: "Thêm khách thuê mới",
  DEACTIVATE_RESIDENT: "Ngừng hoạt động khách thuê",
  REACTIVATE_RESIDENT: "Kích hoạt lại khách thuê",

  CREATE_MOTEL: "Thêm khu trọ mới",
  UPDATE_MOTEL: "Cập nhật thông tin khu trọ",
  DELETE_MOTEL: "Xóa khu trọ",

  SUBMIT_METER_READING: "Ghi chỉ số điện nước",
  APPROVE_METER_READING: "Duyệt chỉ số điện nước",
  COMPLETE_SETTLEMENT: "Tất toán hợp đồng",
  RECEIVE_PAYMENT: "Thu tiền hóa đơn",

  CREATE_INVOICE: "Tạo hóa đơn thanh toán",
  CANCEL_INVOICE: "Hủy hóa đơn",
  DELETE_INVOICE: "Xóa hóa đơn",

  CREATE_CONTRACT: "Tạo hợp đồng thuê phòng",
  ACTIVATE_CONTRACT: "Kích hoạt hợp đồng",
  CANCEL_CONTRACT: "Hủy hợp đồng",
  ADJUST_CONTRACT: "Điều chỉnh hợp đồng",

  COLLECT_DEPOSIT: "Thu tiền cọc",
  REFUND_DEPOSIT: "Hoàn trả tiền cọc",
  DEDUCT_DEPOSIT: "Khấu trừ tiền cọc",

  CREATE_DEVICE: "Thêm thiết bị mới",
  UPDATE_DEVICE: "Cập nhật thiết bị",
  DELETE_DEVICE: "Xóa thiết bị",
};

const ENTITY_LABELS: Record<string, string> = {
  CONTRACT: "Hợp đồng",
  ROOM: "Phòng trọ",
  MOTEL: "Khu trọ",
  INVOICE: "Hóa đơn",
  RESIDENT: "Khách thuê",
  METER_READING: "Chỉ số điện nước",
  SERVICE: "Dịch vụ",
  SERVICE_USAGE: "Đăng ký dịch vụ",
  TRANSACTION: "Giao dịch",
  USER: "Người dùng",
  DEVICE: "Thiết bị",
};

const ROLE_LABELS: Record<string, string> = {
  ADMIN: "Quản trị viên",
  MANAGER: "Quản lý",
  OWNER: "Chủ nhà",
  RESIDENT: "Khách thuê",
  TECHNICIAN: "Kỹ thuật viên",
};

function getActionLabel(action: string | undefined | null) {
  const key = action?.toUpperCase() ?? "";
  return ACTION_LABELS[key] || action || "";
}

function getEntityLabel(entity: string | undefined | null) {
  const key = entity?.toUpperCase() ?? "";
  return ENTITY_LABELS[key] || entity || "";
}

function getRoleLabel(role: string | undefined | null) {
  const key = role?.toUpperCase() ?? "";
  return ROLE_LABELS[key] || role || "";
}

function getActionBadge(action: string | undefined | null) {
  const key = action?.toUpperCase() ?? "";
  const variant = Object.keys(ACTION_VARIANT).find((k) => key.includes(k));
  return (
    <Badge variant={variant ? ACTION_VARIANT[variant] : "default"}>
      {getActionLabel(action)}
    </Badge>
  );
}

function getEntityDescription(type: string | undefined | null, id: string | undefined | null) {
  if (!type) return "-";
  const label = getEntityLabel(type);
  if (!id) return label;
  
  const isUuid = id.length === 36 && id.includes("-");
  if (isUuid) {
    return label;
  }
  
  const typeUpper = type.toUpperCase();
  if (typeUpper === "ROOM") return `Phòng (Mã #${id})`;
  if (typeUpper === "CONTRACT") return `Hợp đồng (Mã #${id})`;
  if (typeUpper === "INVOICE") return `Hóa đơn (Mã #${id})`;
  if (typeUpper === "MOTEL") return `Khu trọ (Mã #${id})`;
  if (typeUpper === "METER_READING") return `Chỉ số (Mã #${id})`;
  if (typeUpper === "SERVICE") return `Dịch vụ (Mã #${id})`;
  
  return `${label} (Mã #${id})`;
}

export function AuditLogPage() {
  const { user } = useAuthStore();
  const isManager = user?.role === "MANAGER";

  const [logs, setLogs] = useState<AuditLogResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [search, setSearch] = useState("");
  const [fromDate, setFromDate] = useState("");

  const fetchLogs = useCallback(async () => {
    setLoading(true);
    try {
      const service = isManager ? activityService : auditService;
      const result = await service.list(page, 20, {
        fromDate: fromDate || undefined,
      });
      setLogs(result.content);
      setTotalPages(result.totalPages);
      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [page, fromDate, isManager]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  const filtered = logs.filter((log) => {
    if (!search) return true;
    const q = search.toLowerCase();
    const actionLabel = getActionLabel(log.action).toLowerCase();
    const entityLabel = getEntityLabel(log.entityType).toLowerCase();
    const roleLabel = getRoleLabel(log.actorRole).toLowerCase();
    const entityDesc = getEntityDescription(log.entityType, log.entityId).toLowerCase();
    
    return (
      actionLabel.includes(q) ||
      entityLabel.includes(q) ||
      roleLabel.includes(q) ||
      entityDesc.includes(q) ||
      (log.ipAddress && log.ipAddress.toLowerCase().includes(q))
    );
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Nhật ký hoạt động</h1>
          <p className="text-sm text-slate-500 mt-1">Giám sát toàn bộ thao tác hệ thống</p>
        </div>
        <Button variant="outline" onClick={fetchLogs} disabled={loading}>
          <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
        </Button>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center gap-4">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              id="audit-search"
              type="text"
              placeholder="Tìm kiếm theo hành động, đối tượng..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="h-10 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-brand-deep focus:outline-none focus:ring-2 focus:ring-brand-deep/20 transition-all"
            />
          </div>
          <input
            id="audit-from-date"
            type="date"
            value={fromDate}
            onChange={(e) => setFromDate(e.target.value)}
            className="h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 focus:border-brand-deep bg-white"
          />
        </div>

        {error ? (
          <div className="p-8 flex flex-col items-center text-center">
            <AlertCircle size={32} className="text-red-400 mb-3" />
            <p className="text-slate-600 text-sm">{error}</p>
            <Button className="mt-4" size="sm" onClick={fetchLogs}>Thử lại</Button>
          </div>
        ) : loading ? (
          <div className="p-12 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-deep border-t-transparent" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 flex flex-col items-center text-center">
            <Activity size={40} className="text-slate-200 mb-3" />
            <p className="text-slate-500 font-medium">Chưa có nhật ký nào</p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Thời gian</TableHead>
                <TableHead>Người thực hiện</TableHead>
                <TableHead>Hành động</TableHead>
                <TableHead>Đối tượng tác động</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((log) => (
                <TableRow key={log.id} className="hover:bg-slate-50/50 transition-colors">
                  <TableCell className="text-xs text-slate-400 whitespace-nowrap">
                    {log.timestamp
                      ? new Date(log.timestamp).toLocaleString("vi-VN")
                      : "-"}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm font-medium text-brand-ink">
                      {getRoleLabel(log.actorRole) || "Hệ thống"}
                    </div>
                    <div className="text-xs text-slate-400">IP: {log.ipAddress || "Không rõ"}</div>
                  </TableCell>
                  <TableCell>{getActionBadge(log.action)}</TableCell>
                  <TableCell className="text-sm text-slate-600 font-medium">
                    {getEntityDescription(log.entityType, log.entityId)}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}

        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-100 flex justify-center gap-2">
            <Button variant="outline" size="sm" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>
              Trước
            </Button>
            <span className="px-4 py-1.5 text-sm text-slate-600">{page + 1} / {totalPages}</span>
            <Button variant="outline" size="sm" disabled={page >= totalPages - 1} onClick={() => setPage((p) => p + 1)}>
              Sau
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

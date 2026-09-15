import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  Building2, Users, FileText, AlertCircle, TrendingUp,
  TrendingDown, Wallet, CheckCircle2, Clock, ArrowRight,
  RefreshCw, ChevronRight, CreditCard, Sparkles, HelpCircle, Check, ArrowRightCircle
} from "lucide-react";
import { formatCurrency } from "@/lib/utils";
import { reportService, activityService, type DashboardSummaryResult } from "@/services/reportService";
import { extractError } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { invoiceService, type InvoiceResult } from "@/services/invoiceService";
import { VietQrPaymentModal } from "@/features/invoices/components/VietQrPaymentModal";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { motelService, type MotelResult } from "@/services/motelService";
import { serviceService } from "@/services/serviceService";
import { useTourGuide } from "@/hooks/useTourGuide";

function StatCard({
  title,
  value,
  icon: Icon,
  iconBg,
  iconColor,
  sub,
  trend,
}: {
  title: string;
  value: string | number;
  icon: React.ElementType;
  iconBg: string;
  iconColor: string;
  sub?: React.ReactNode;
  trend?: { value: string; up: boolean };
}) {
  return (
    <div className="rounded-2xl bg-white p-6 shadow-sm border border-slate-100 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-slate-500 truncate">{title}</p>
          <h3 className="text-2xl font-bold text-brand-ink mt-1 font-display">{value}</h3>
        </div>
        <div className={`p-3 ${iconBg} rounded-xl ml-3 flex-shrink-0`}>
          <Icon size={22} className={iconColor} />
        </div>
      </div>
      <div className="mt-4 flex items-center gap-2 text-sm">
        {trend && (
          <span className={`flex items-center gap-1 font-medium ${trend.up ? "text-green-600" : "text-red-500"}`}>
            {trend.up ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
            {trend.value}
          </span>
        )}
        {sub && <span className="text-slate-500">{sub}</span>}
      </div>
    </div>
  );
}

const bankOptions = [
  { id: "MB", name: "MBBank" },
  { id: "VCB", name: "Vietcombank" },
  { id: "ICB", name: "VietinBank" },
  { id: "ACB", name: "ACB" },
  { id: "BIDV", name: "BIDV" },
  { id: "TCB", name: "Techcombank" },
  { id: "VIB", name: "VIB" },
];

export function DashboardPage() {
  const { user } = useAuthStore();
  const { hasCompletedOnboarding, setIsGuideOpen } = useTourGuide();
  const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";

  // Manager state
  const [data, setData] = useState<DashboardSummaryResult | null>(null);

  // Common states
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  // Tenant states
  const [tenantInvoices, setTenantInvoices] = useState<InvoiceResult[]>([]);
  const [paymentInvoice, setPaymentInvoice] = useState<InvoiceResult | null>(null);
  const [managerActivities, setManagerActivities] = useState<any[]>([]);
  const [creditBalance, setCreditBalance] = useState<number>(0);

  const fetchData = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);
    try {
      if (isTenant) {
        // Fetch only tenant invoices and balance
        const [res, bal] = await Promise.all([
          invoiceService.listMine(undefined, 0, 50),
          invoiceService.getMyBalance().catch(() => 0)
        ]);
        setTenantInvoices(res.content || []);
        setCreditBalance(bal);
      } else {
        if (!hasCompletedOnboarding) {
          // Set rich dummy summary data
          setData({
            expectedRevenue: 15200000,
            collectedRevenue: 11700000,
            occupancyRate: 75,
            rentedRooms: 6,
            totalRooms: 8,
            expiringContractsCount: 1,
            unpaidInvoicesCount: 2,
            pendingDebt: 3500000,
            recentInvoices: [
              { invoiceId: 991, roomNumber: "101", billingMonth: "06/2026", amount: 2500000, status: "PAID" },
              { invoiceId: 992, roomNumber: "102", billingMonth: "06/2026", amount: 3200000, status: "PAID" },
              { invoiceId: 993, roomNumber: "103", billingMonth: "06/2026", amount: 2100000, status: "PAID" },
              { invoiceId: 994, roomNumber: "201", billingMonth: "06/2026", amount: 2800000, status: "PENDING" },
              { invoiceId: 995, roomNumber: "202", billingMonth: "06/2026", amount: 2600000, status: "PENDING" }
            ],
            recentActivities: [
              { description: "Đã duyệt chỉ số nước Phòng 101", createdAt: new Date(Date.now() - 3600000).toISOString() },
              { description: "Hệ thống tự động đồng bộ hóa hóa đơn Phòng 102 qua SePay", createdAt: new Date(Date.now() - 7200000).toISOString() },
              { description: "Đã lập hợp đồng mới cho khách hàng Nguyễn Văn A", createdAt: new Date(Date.now() - 86400000).toISOString() }
            ]
          } as any);
        } else {
          const result = await reportService.getDashboardSummary();
          setData(result);

          if (user?.role === "MANAGER") {
            try {
              const logsResult = await activityService.list(0, 5);
              const mapped = logsResult.content.map(log => ({
                description: `${log.action} ${log.entityType || ""} (Mã: ${log.entityId || ""})`,
                createdAt: log.timestamp
              }));
              setManagerActivities(mapped);
            } catch (logErr) {
              console.error("Failed to load manager activity logs", logErr);
            }
          }
        }
      }
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };;

  useEffect(() => {
    fetchData();
  }, [hasCompletedOnboarding]);

  if (loading) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-8 bg-slate-100 rounded-lg w-48" />
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-36 rounded-2xl bg-slate-100" />
          ))}
        </div>
        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2 h-64 rounded-2xl bg-slate-100" />
          <div className="h-64 rounded-2xl bg-slate-100" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] text-center">
        <div className="p-4 bg-red-50 rounded-2xl mb-4">
          <AlertCircle size={32} className="text-red-400" />
        </div>
        <p className="text-slate-600 mb-4">{error}</p>
        <button
          onClick={() => fetchData()}
          className="px-4 py-2 bg-brand-deep text-white rounded-xl text-sm font-medium hover:bg-brand-deep/90 transition-colors"
        >
          Thử lại
        </button>
      </div>
    );
  }

  // ==================== TENANT VIEW ====================
  if (isTenant) {
    const unpaidInvoices = tenantInvoices.filter(inv => inv.status !== "PAID");
    const unpaidCount = unpaidInvoices.length;
    const totalDebt = unpaidInvoices.reduce((sum, inv) => sum + (inv.totalAmount - (inv.paidAmount || 0)), 0);
    const myRoom = tenantInvoices.length > 0
      ? (tenantInvoices[0].roomNumber ? `Phòng P.${tenantInvoices[0].roomNumber}` : `Phòng #${tenantInvoices[0].roomId}`)
      : "Chưa xác định";

    return (
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold font-display text-brand-ink">Xin chào, {user?.name}!</h1>
            <p className="text-sm text-slate-500 mt-1">
              Cổng thông tin khách thuê • {new Date().toLocaleDateString("vi-VN", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}
            </p>
          </div>
          <button
            onClick={() => fetchData(true)}
            disabled={refreshing}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-50 transition-all disabled:opacity-50"
          >
            <RefreshCw size={16} className={refreshing ? "animate-spin" : ""} />
            Làm mới
          </button>
        </div>

        {/* Tenant KPI Cards */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="Số hóa đơn cần thanh toán"
            value={`${unpaidCount} hóa đơn`}
            icon={AlertCircle}
            iconBg="bg-rose-100"
            iconColor="text-rose-600"
            sub={unpaidCount > 0 ? "Vui lòng thanh toán đúng hạn" : "Không có hóa đơn trễ hạn"}
          />
          <StatCard
            title="Tổng dư nợ hiện tại"
            value={formatCurrency(totalDebt)}
            icon={Wallet}
            iconBg="bg-amber-100"
            iconColor="text-amber-600"
            sub="Cần thanh toán qua ngân hàng"
          />
          <StatCard
            title="Số dư tài khoản"
            value={formatCurrency(creditBalance)}
            icon={Wallet}
            iconBg="bg-blue-100"
            iconColor="text-blue-600"
            sub="Dùng để cấn trừ hóa đơn tự động"
          />
          <StatCard
            title="Phòng thuê của tôi"
            value={myRoom}
            icon={Building2}
            iconBg="bg-emerald-100"
            iconColor="text-emerald-600"
            sub="Trạng thái: Đang ở"
          />
        </div>

        {/* Main layout */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Unpaid invoices / Invoice History */}
          <div className="lg:col-span-2 rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h2 className="font-semibold text-brand-ink">Hóa đơn của tôi</h2>
              <Link
                to="/invoices"
                className="text-sm text-brand-deep font-medium flex items-center gap-1 hover:underline"
              >
                Tất cả hóa đơn <ChevronRight size={14} />
              </Link>
            </div>
            <div className="p-6">
              {tenantInvoices.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-center text-slate-500">
                  <CheckCircle2 size={32} className="text-emerald-400 mb-2" />
                  <p className="text-sm font-medium">Bạn chưa có hóa đơn nào</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {tenantInvoices.slice(0, 5).map((inv) => {
                    const remainingDebt = inv.totalAmount - (inv.paidAmount || 0);
                    return (
                      <div
                        key={inv.id}
                        className="flex items-center justify-between p-4 rounded-xl border border-slate-100 hover:bg-slate-50 transition-colors"
                      >
                        <div className="space-y-1">
                          <div className="flex items-center gap-2">
                            <span className="text-sm font-bold text-slate-800">Kỳ {inv.billingMonth}</span>
                            {inv.status === "PAID" ? (
                              <span className="text-xs bg-emerald-100 text-emerald-700 px-2.5 py-0.5 rounded-full font-medium">Đã đóng</span>
                            ) : inv.status === "PARTIAL" ? (
                              <span className="text-xs bg-amber-100 text-amber-700 px-2.5 py-0.5 rounded-full font-medium font-mono">Đóng một phần</span>
                            ) : (
                              <span className="text-xs bg-red-100 text-red-700 px-2.5 py-0.5 rounded-full font-medium">Chưa thanh toán</span>
                            )}
                          </div>
                          <p className="text-xs text-slate-400">
                            Loại: {inv.invoiceType === "MONTHLY" ? "Tiền nhà hàng tháng" : "Chi phí khác"}
                          </p>
                        </div>
                        <div className="flex items-center gap-4">
                          <div className="text-right">
                            <p className="text-sm font-extrabold text-slate-800">{formatCurrency(inv.totalAmount)}</p>
                            {remainingDebt > 0 && remainingDebt !== inv.totalAmount && (
                              <p className="text-xs text-rose-500 font-medium">Còn nợ: {formatCurrency(remainingDebt)}</p>
                            )}
                          </div>
                          {inv.status !== "PAID" && (
                            <Button
                              size="sm"
                              className="bg-brand-deep hover:bg-brand-deep/90 text-white font-medium"
                              onClick={() => setPaymentInvoice(inv)}
                            >
                              Thanh toán
                            </Button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Quick manual payment info */}
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden p-6 space-y-4">
            <h3 className="font-bold text-brand-ink border-b border-slate-100 pb-3 flex items-center gap-2">
              <CreditCard size={18} className="text-brand-deep" />
              Thông tin chuyển khoản
            </h3>
            <div className="space-y-3 text-sm">
              <div className="bg-slate-50 p-4 rounded-xl space-y-3 border border-slate-150">
                <div>
                  <span className="text-xs text-slate-400 block">Ngân hàng</span>
                  <span className="font-bold text-slate-800 text-sm">MB Bank</span>
                </div>
                <div>
                  <span className="text-xs text-slate-400 block">Số tài khoản</span>
                  <span className="font-mono font-bold text-brand-deep text-base">1903 0456 7899</span>
                </div>
                <div>
                  <span className="text-xs text-slate-400 block">Chủ tài khoản</span>
                  <span className="font-bold text-slate-850 uppercase">NGUYEN TRAN PHUONG (CHU TRO)</span>
                </div>
              </div>
              <div className="text-xs text-slate-500 leading-relaxed bg-amber-50 border border-amber-100 rounded-xl p-3">
                ⚠️ <strong>Lưu ý:</strong> Khi chuyển khoản qua ứng dụng, quý khách vui lòng nhập đúng nội dung chuyển khoản theo định dạng <strong>SMARTBOARDING HD[Mã hóa đơn]</strong> để hệ thống tự động ghi nhận và duyệt hóa đơn cho bạn nhanh chóng nhất.
              </div>
            </div>
          </div>
        </div>

        {paymentInvoice && (
          <VietQrPaymentModal
            isOpen={!!paymentInvoice}
            onClose={() => setPaymentInvoice(null)}
            invoiceId={paymentInvoice.id}
            onSuccess={() => {
              setPaymentInvoice(null);
              fetchData();
            }}
          />
        )}
      </div>
    );
  }

  // ==================== MANAGER VIEW ====================
  const collectionRate = data && data.expectedRevenue > 0
    ? Math.round((data.collectedRevenue / data.expectedRevenue) * 100)
    : 0;

  return (
    <div className="relative">
      <div className="space-y-6">
        {/* Onboarding Mode Banner Indicator */}
        {!hasCompletedOnboarding && (
          <div className="bg-gradient-to-r from-amber-500 to-orange-600 text-white font-bold px-5 py-4 rounded-2xl flex items-center justify-between shadow-lg animate-pulse mb-6">
            <div className="flex items-center gap-3 text-base md:text-lg">
              <AlertCircle size={24} className="text-white" />
              <span>Môi trường thử nghiệm (Dữ liệu mẫu) - Bác hãy hoàn thành 6 bước thiết lập trọn vẹn để chuyển sang quản lý thực tế.</span>
            </div>
            <button
              onClick={() => setIsGuideOpen(true)}
              className="bg-white text-orange-600 hover:bg-slate-50 font-bold px-4 py-2 rounded-xl text-xs sm:text-sm transition-all shadow-md active:scale-95 cursor-pointer font-sans"
            >
              Mở trợ lý hướng dẫn
            </button>
          </div>
        )}

        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold font-display text-brand-ink">
              {!hasCompletedOnboarding ? "Tổng quan hệ thống (Trực quan thử nghiệm)" : "Tổng quan hệ thống"}
            </h1>
            <p className="text-sm text-slate-500 mt-1">
              Dữ liệu theo thời gian thực • {new Date().toLocaleDateString("vi-VN", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}
            </p>
          </div>
          <button
            onClick={() => fetchData(true)}
            disabled={refreshing}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-650 hover:bg-slate-50 transition-all disabled:opacity-50"
          >
            <RefreshCw size={16} className={refreshing ? "animate-spin" : ""} />
            Làm mới
          </button>
        </div>

        {/* KPI Cards */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="Doanh thu dự kiến"
            value={formatCurrency(data?.expectedRevenue ?? 0)}
            icon={Wallet}
            iconBg="bg-violet-100"
            iconColor="text-violet-600"
            sub={`Đã thu: ${collectionRate}%`}
            trend={{ value: `${collectionRate}%`, up: collectionRate >= 80 }}
          />
          <StatCard
            title="Tỷ lệ lấp đầy"
            value={`${data ? Math.round(data.occupancyRate) : 0}%`}
            icon={Building2}
            iconBg="bg-emerald-100"
            iconColor="text-emerald-600"
            sub={`${data?.rentedRooms ?? 0}/${data?.totalRooms ?? 0} phòng đang thuê`}
          />
          <StatCard
            title="Hợp đồng sắp hết hạn"
            value={data?.expiringContractsCount ?? 0}
            icon={FileText}
            iconBg="bg-amber-100"
            iconColor="text-amber-600"
            sub="Trong 30 ngày tới"
          />
          <StatCard
            title="Hóa đơn chưa thanh toán"
            value={data?.unpaidInvoicesCount ?? 0}
            icon={AlertCircle}
            iconBg="bg-rose-100"
            iconColor="text-rose-600"
            sub={`Nợ: ${formatCurrency(data?.pendingDebt ?? 0)}`}
          />
        </div>

        {/* Revenue overview + Alerts */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Revenue detail */}
          <div className="lg:col-span-2 rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <h2 className="font-semibold text-brand-ink">Tài chính tháng này</h2>
              <Link
                to="/reports"
                className="text-sm text-brand-deep font-medium flex items-center gap-1 hover:underline"
              >
                Xem báo cáo <ChevronRight size={14} />
              </Link>
            </div>
            <div className="p-6 space-y-4">
              {/* Progress bar */}
              <div>
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-slate-500">Tiến độ thu tiền</span>
                  <span className="font-semibold text-brand-ink">{collectionRate}%</span>
                </div>
                <div className="h-3 bg-slate-100 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-emerald-400 to-emerald-600 transition-all duration-700"
                    style={{ width: `${collectionRate}%` }}
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4 pt-2">
                {[
                  { label: "Dự kiến", value: data?.expectedRevenue, color: "text-slate-700", bg: "bg-slate-50" },
                  { label: "Đã thu", value: data?.collectedRevenue, color: "text-emerald-700", bg: "bg-emerald-50" },
                  { label: "Còn nợ", value: data?.pendingDebt, color: "text-rose-700", bg: "bg-rose-50" },
                ].map((item) => (
                  <div key={item.label} className={`${item.bg} rounded-xl p-4 text-center`}>
                    <div className={`text-lg font-bold font-display ${item.color}`}>
                      {formatCurrency(item.value ?? 0)}
                    </div>
                    <div className="text-xs text-slate-500 mt-1">{item.label}</div>
                  </div>
                ))}
              </div>

              {/* Recent invoices */}
              {data && data.recentInvoices.length > 0 && (
                <div className="pt-4 border-t border-slate-100">
                  <h3 className="text-sm font-medium text-slate-600 mb-3">Hóa đơn gần đây</h3>
                  <div className="space-y-2">
                    {data.recentInvoices.slice(0, 4).map((inv) => (
                      <div key={inv.invoiceId} className="flex items-center justify-between py-2 px-3 rounded-lg hover:bg-slate-50 transition-colors">
                        <div className="flex items-center gap-3">
                          <div className={`w-2 h-2 rounded-full ${inv.status === "PAID" ? "bg-emerald-500" :
                              inv.status === "PARTIAL" ? "bg-amber-500" : "bg-rose-500"
                            }`} />
                          <div>
                            <span className="text-sm font-medium text-slate-700">
                              {inv.roomNumber ? `Phòng ${inv.roomNumber}` : `HĐ #${inv.invoiceId}`}
                            </span>
                            <span className="text-xs text-slate-400 ml-2">
                              {inv.billingMonth}
                            </span>
                          </div>
                        </div>
                        <span className="text-sm font-semibold text-brand-ink">{formatCurrency(inv.amount)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Action required */}
          <div className="rounded-2xl bg-white border border-slate-100 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100">
              <h2 className="font-semibold text-brand-ink">Cần xử lý</h2>
            </div>
            <div className="p-6 space-y-3">
              {data && data.unpaidInvoicesCount > 0 && (
                <Link
                  to="/invoices?status=PENDING"
                  className="flex items-start gap-3 p-3 rounded-xl bg-rose-50 border border-rose-100 hover:border-rose-200 transition-colors group"
                >
                  <AlertCircle className="text-rose-500 mt-0.5 flex-shrink-0" size={18} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-rose-800">
                      {data.unpaidInvoicesCount} hóa đơn chưa thanh toán
                    </p>
                    <p className="text-xs text-rose-600 mt-0.5">
                      Tổng nợ: {formatCurrency(data.pendingDebt)}
                    </p>
                  </div>
                  <ArrowRight size={14} className="text-rose-400 mt-1 group-hover:translate-x-1 transition-transform" />
                </Link>
              )}

              {data && data.expiringContractsCount > 0 && (
                <Link
                  to="/contracts?filter=expiring"
                  className="flex items-start gap-3 p-3 rounded-xl bg-amber-50 border border-amber-100 hover:border-amber-200 transition-colors group"
                >
                  <Clock className="text-amber-500 mt-0.5 flex-shrink-0" size={18} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-amber-800">
                      {data.expiringContractsCount} hợp đồng sắp hết hạn
                    </p>
                    <p className="text-xs text-amber-600 mt-0.5">Cần gia hạn trong 30 ngày</p>
                  </div>
                  <ArrowRight size={14} className="text-amber-400 mt-1 group-hover:translate-x-1 transition-transform" />
                </Link>
              )}

              {data && data.pendingMeterReadingsCount > 0 && (
                <Link
                  to="/meter-readings"
                  className="flex items-start gap-3 p-3 rounded-xl bg-blue-50 border border-blue-100 hover:border-blue-200 transition-colors group"
                >
                  <AlertCircle className="text-blue-500 mt-0.5 flex-shrink-0" size={18} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-blue-800">
                      {data.pendingMeterReadingsCount} chỉ số chờ duyệt
                    </p>
                    <p className="text-xs text-blue-605 mt-0.5 font-sans">Ghi chỉ số điện nước</p>
                  </div>
                  <ArrowRight size={14} className="text-blue-400 mt-1 group-hover:translate-x-1 transition-transform" />
                </Link>
              )}

              {(!data || (data.unpaidInvoicesCount === 0 && data.expiringContractsCount === 0 && data.pendingMeterReadingsCount === 0)) && (
                <div className="flex flex-col items-center justify-center py-8 text-center">
                  <CheckCircle2 size={32} className="text-emerald-400 mb-3" />
                  <p className="text-sm font-medium text-slate-600">Không có việc cần xử lý</p>
                  <p className="text-xs text-slate-400 mt-1">Hệ thống đang hoạt động bình thường</p>
                </div>
              )}

              {/* Activities */}
              {(() => {
                const activitiesToDisplay = (user?.role === "MANAGER" && managerActivities.length > 0)
                  ? managerActivities
                  : (data?.recentActivities || []);

                if (activitiesToDisplay.length === 0) return null;

                return (
                  <div className="pt-4 border-t border-slate-100 font-sans">
                    <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wider mb-3">Hoạt động gần đây</h3>
                    <div className="space-y-3">
                      {activitiesToDisplay.slice(0, 3).map((act, i) => (
                        <div key={i} className="flex gap-3 relative">
                          {i < activitiesToDisplay.slice(0, 3).length - 1 && (
                            <div className="absolute left-[7px] top-5 bottom-[-12px] w-px bg-slate-200" />
                          )}
                          <div className="relative z-10 w-3.5 h-3.5 rounded-full bg-brand-deep/20 border-2 border-white mt-1 flex-shrink-0" />
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-medium text-brand-ink truncate">{act.description}</p>
                            <p className="text-xs text-slate-400 mt-0.5">
                              {act.createdAt ? new Date(act.createdAt).toLocaleString("vi-VN", { hour: "2-digit", minute: "2-digit", day: "2-digit", month: "2-digit" }) : "-"}
                            </p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })()}
            </div>
          </div>
        </div>

        {/* Quick actions */}
        <div className="rounded-2xl bg-gradient-to-br from-brand-deep to-slate-800 p-6 text-white font-sans">
          <h2 className="font-semibold mb-4">Thao tác nhanh</h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {[
              { label: "Tạo hóa đơn", icon: Wallet, href: "/invoices?action=generate" },
              { label: "Thêm khách thuê", icon: Users, href: "/residents?action=new" },
              { label: "Tạo hợp đồng", icon: FileText, href: "/contracts?action=new" },
              { label: "Ghi chỉ số", icon: TrendingUp, href: "/meter-readings" },
            ].map((item) => (
              <Link
                key={item.label}
                to={item.href}
                className="flex items-center gap-3 p-4 bg-white/10 rounded-xl hover:bg-white/20 transition-colors backdrop-blur"
              >
                <item.icon size={20} />
                <span className="text-sm font-medium">{item.label}</span>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

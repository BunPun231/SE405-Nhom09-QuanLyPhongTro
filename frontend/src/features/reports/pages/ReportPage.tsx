import { useState, useEffect, useCallback } from "react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, LineChart, Line, Legend
} from "recharts";
import { formatCurrency } from "@/lib/utils";
import {
  reportService,
  type RevenueReportResult,
  type OccupancyReportResult,
  type DebtReportResult,
} from "@/services/reportService";
import { motelService, type MotelResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { AlertCircle, RefreshCw, TrendingUp, Building2, CreditCard, BarChart2 } from "lucide-react";
import { Button } from "@/components/ui/Button";

const OCCUPANCY_COLORS = ["#10b981", "#6366f1", "#f59e0b", "#ef4444", "#94a3b8"];

const TABS = [
  { id: "revenue", label: "Doanh thu", icon: TrendingUp },
  { id: "occupancy", label: "Công suất", icon: Building2 },
  { id: "debt", label: "Công nợ", icon: CreditCard },
] as const;

type TabId = "revenue" | "occupancy" | "debt";

export function ReportPage() {
  const [activeTab, setActiveTab] = useState<TabId>("revenue");
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [year, setYear] = useState(new Date().getFullYear());

  const [revenueData, setRevenueData] = useState<RevenueReportResult | null>(null);
  const [occupancyData, setOccupancyData] = useState<OccupancyReportResult | null>(null);
  const [debtData, setDebtData] = useState<DebtReportResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    motelService.list().then((res) => {
      setMotels(res.content);
      if (res.content.length > 0) setSelectedMotelId(res.content[0].id);
    });
  }, []);

  const fetchData = useCallback(async () => {
    if (!selectedMotelId) return;
    setLoading(true);
    setError(null);
    try {
      if (activeTab === "revenue") {
        setRevenueData(await reportService.getRevenue(selectedMotelId, year));
      } else if (activeTab === "occupancy") {
        setOccupancyData(await reportService.getOccupancy(selectedMotelId));
      } else if (activeTab === "debt") {
        setDebtData(await reportService.getDebt(selectedMotelId));
      }
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [activeTab, selectedMotelId, year]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const selectClass = "h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 focus:border-brand-deep bg-white";

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Báo cáo & Thống kê</h1>
          <p className="text-sm text-slate-500 mt-1">Phân tích dữ liệu kinh doanh</p>
        </div>
        <div className="flex gap-2">
          <select
            id="report-motel"
            value={selectedMotelId ?? ""}
            onChange={(e) => setSelectedMotelId(Number(e.target.value))}
            className={selectClass}
          >
            {motels.map((m) => (
              <option key={m.id} value={m.id}>{m.name}</option>
            ))}
          </select>
          {activeTab === "revenue" && (
            <select
              id="report-year"
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              className={selectClass}
            >
              {[2024, 2025, 2026, 2027].map((y) => (
                <option key={y} value={y}>Năm {y}</option>
              ))}
            </select>
          )}
          <button
            onClick={fetchData}
            disabled={loading}
            className="flex items-center gap-2 px-3 h-10 border border-slate-200 rounded-xl text-sm text-slate-600 hover:bg-slate-50 transition-all disabled:opacity-50"
          >
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-slate-100 rounded-xl w-fit">
        {TABS.map((tab) => (
          <button
            key={tab.id}
            id={`report-tab-${tab.id}`}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeTab === tab.id
                ? "bg-white text-brand-ink shadow-sm"
                : "text-slate-500 hover:text-slate-700"
            }`}
          >
            <tab.icon size={16} />
            {tab.label}
          </button>
        ))}
      </div>

      {error && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 border border-red-100 p-4 text-red-700">
          <AlertCircle size={20} />
          <span className="text-sm">{error}</span>
          <Button size="sm" variant="outline" onClick={fetchData} className="ml-auto">Thử lại</Button>
        </div>
      )}

      {loading ? (
        <div className="flex justify-center py-24">
          <div className="animate-spin rounded-full h-10 w-10 border-2 border-brand-deep border-t-transparent" />
        </div>
      ) : (
        <>
          {/* Revenue Tab */}
          {activeTab === "revenue" && revenueData && (
            <div className="space-y-6">
              {/* Summary */}
              <div className="grid gap-4 md:grid-cols-3">
                {[
                  { label: "Dự kiến cả năm", value: revenueData.totalProjected, color: "text-brand-ink" },
                  { label: "Thực thu cả năm", value: revenueData.totalActual, color: "text-emerald-600" },
                  { label: "Tỷ lệ thu hồi", value: `${(revenueData.collectionRate ?? 0).toFixed(1)}%`, color: "text-violet-600", isText: true },
                ].map((item) => (
                  <div key={item.label} className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100">
                    <p className="text-sm text-slate-500">{item.label}</p>
                    <h3 className={`text-2xl font-bold mt-1 font-display ${item.color}`}>
                      {item.isText ? item.value : formatCurrency(item.value as number)}
                    </h3>
                  </div>
                ))}
              </div>

              <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm">
                <h3 className="font-semibold text-brand-ink mb-6 flex items-center gap-2">
                  <BarChart2 size={18} className="text-brand-deep" />
                  Doanh thu dự kiến vs. thực thu ({year})
                </h3>
                <div className="h-72 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart
                      data={revenueData.monthly.map((m) => ({
                        name: `T${m.month}`,
                        "Dự kiến": m.projected,
                        "Thực thu": m.actual,
                      }))}
                      margin={{ top: 10, right: 10, left: 20, bottom: 0 }}
                      barGap={4}
                    >
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                      <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12 }} />
                      <YAxis
                        tickFormatter={(v) => `${(v / 1000000).toFixed(0)}M`}
                        axisLine={false}
                        tickLine={false}
                        tick={{ fontSize: 12 }}
                      />
                      <Tooltip
                        formatter={(v) => [formatCurrency(Number(v)), ""]}
                        contentStyle={{ borderRadius: 12, border: "1px solid #e2e8f0" }}
                      />
                      <Legend />
                      <Bar dataKey="Dự kiến" fill="#c4b5fd" radius={[4, 4, 0, 0]} />
                      <Bar dataKey="Thực thu" fill="#10b981" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
          )}

          {/* Occupancy Tab */}
          {activeTab === "occupancy" && occupancyData && (
            <div className="space-y-6">
              <div className="grid gap-4 md:grid-cols-4">
                {[
                  { label: "Tổng phòng", value: occupancyData.totalRooms, color: "text-brand-ink" },
                  { label: "Đang thuê", value: occupancyData.rentedRooms, color: "text-blue-600" },
                  { label: "Đặt cọc", value: occupancyData.depositedRooms, color: "text-violet-600" },
                  { label: "Còn trống", value: occupancyData.availableRooms, color: "text-emerald-600" },
                ].map((item) => (
                  <div key={item.label} className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100">
                    <p className="text-sm text-slate-500">{item.label}</p>
                    <h3 className={`text-3xl font-bold mt-1 font-display ${item.color}`}>{item.value}</h3>
                  </div>
                ))}
              </div>

              <div className="grid gap-6 lg:grid-cols-2">
                <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm flex flex-col">
                  <h3 className="font-semibold text-brand-ink mb-4">Tỷ lệ lấp đầy</h3>
                  <div className="flex-1 relative min-h-[200px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={[
                            { name: "Đang thuê", value: occupancyData.rentedRooms },
                            { name: "Đặt cọc", value: occupancyData.depositedRooms },
                            { name: "Còn trống", value: occupancyData.availableRooms },
                            { name: "Sửa chữa", value: occupancyData.repairingRooms },
                          ].filter((d) => d.value > 0)}
                          cx="50%"
                          cy="50%"
                          innerRadius={60}
                          outerRadius={90}
                          paddingAngle={4}
                          dataKey="value"
                        >
                          {OCCUPANCY_COLORS.map((color, idx) => (
                            <Cell key={idx} fill={color} />
                          ))}
                        </Pie>
                        <Tooltip />
                      </PieChart>
                    </ResponsiveContainer>
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                      <div className="text-center">
                        <p className="text-3xl font-bold text-brand-ink">
                          {Math.round(occupancyData.occupancyRate)}%
                        </p>
                        <p className="text-xs text-slate-500 mt-1">Lấp đầy</p>
                      </div>
                    </div>
                  </div>
                </div>

                {occupancyData.emptyRooms.length > 0 && (
                  <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm">
                    <h3 className="font-semibold text-brand-ink mb-4">
                      Phòng trống ({occupancyData.emptyRooms.length})
                    </h3>
                    <div className="space-y-2 max-h-64 overflow-y-auto">
                      {occupancyData.emptyRooms.map((room) => (
                        <div
                          key={room.roomId}
                          className="flex items-center justify-between py-2 px-3 rounded-xl hover:bg-slate-50 transition-colors"
                        >
                          <div>
                            <span className="font-medium text-slate-700">Phòng {room.roomNumber}</span>
                            <span className="text-xs text-slate-400 ml-2">Tầng {room.floor}</span>
                          </div>
                          <span className="text-sm font-semibold text-brand-deep">
                            {formatCurrency(room.basePrice)}/tháng
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Debt Tab */}
          {activeTab === "debt" && debtData && (
            <div className="space-y-6">
              <div className="grid gap-4 md:grid-cols-2">
                <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 border-l-4 border-l-rose-400">
                  <p className="text-sm text-slate-500">Tổng công nợ</p>
                  <h3 className="text-2xl font-bold mt-1 font-display text-rose-600">
                    {formatCurrency(debtData.totalDebt)}
                  </h3>
                </div>
                <div className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100">
                  <p className="text-sm text-slate-500">Số hóa đơn nợ</p>
                  <h3 className="text-2xl font-bold mt-1 font-display text-brand-ink">{debtData.debtorCount}</h3>
                </div>
              </div>

              <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
                <div className="p-4 border-b border-slate-100">
                  <h3 className="font-semibold text-brand-ink">Chi tiết công nợ</h3>
                </div>
                {debtData.entries.length === 0 ? (
                  <div className="p-12 text-center text-slate-400">
                    <AlertCircle size={32} className="mx-auto mb-3 text-slate-200" />
                    <p>Không có công nợ</p>
                  </div>
                ) : (
                  <div className="divide-y divide-slate-100">
                    {debtData.entries.map((entry) => (
                      <div key={entry.invoiceId} className="flex items-center justify-between p-4 hover:bg-slate-50 transition-colors">
                        <div>
                          <div className="font-medium text-slate-700">Phòng {entry.roomNumber}</div>
                          <div className="text-xs text-slate-400 mt-0.5">
                            {entry.billingMonth
                              ? new Date(entry.billingMonth).toLocaleDateString("vi-VN", { month: "long", year: "numeric" })
                              : ""}
                            {entry.daysOverdue > 0 && (
                              <span className="ml-2 text-rose-500">Quá hạn {entry.daysOverdue} ngày</span>
                            )}
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="font-bold text-rose-600">{formatCurrency(entry.debtAmount)}</div>
                          <span className={`text-xs px-2 py-0.5 rounded-full ${
                            entry.agingBucket === "BAD_DEBT"
                              ? "bg-rose-100 text-rose-700"
                              : entry.agingBucket === "OVERDUE"
                              ? "bg-amber-100 text-amber-700"
                              : "bg-slate-100 text-slate-600"
                          }`}>
                            {entry.agingBucket === "BAD_DEBT" ? "Nợ xấu" : entry.agingBucket === "OVERDUE" ? "Quá hạn" : "Mới"}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

import { useState, useEffect } from "react";
import { 
  Users, 
  ShieldCheck, 
  ArrowUpRight, 
  CheckCircle2, 
  Server,
  Lock
} from "lucide-react";
import { adminService, ManagerResponse } from "@/services/adminService";
import { Link } from "react-router-dom";

export function SuperAdminDashboardPage() {
  const [managers, setManagers] = useState<ManagerResponse[]>([]);
  const [totalManagers, setTotalManagers] = useState(0);
  const [activeManagers, setActiveManagers] = useState(0);
  const [lockedManagers, setLockedManagers] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminService.getManagers({ page: 0, size: 5 })
      .then(res => {
        setManagers(res.content);
        setTotalManagers(res.totalElements);
        const active = res.content.filter(m => m.status === "ACTIVE").length;
        const locked = res.content.filter(m => m.status === "LOCKED").length;
        setActiveManagers(active);
        setLockedManagers(locked);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-8">
      {/* Top Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-indigo-700 via-indigo-600 to-indigo-800 p-8 shadow-xl text-white">
        <div className="relative z-10 max-w-2xl space-y-3">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/15 border border-white/20 text-white text-xs font-semibold backdrop-blur">
            <ShieldCheck size={14} /> Super Admin Control Center
          </div>
          <h1 className="text-3xl font-bold font-display tracking-tight">
            Hệ thống Quản trị SmartBoarding SaaS
          </h1>
          <p className="text-indigo-100 text-sm leading-relaxed">
            Giám sát các Chủ nhà (Managers), kiểm soát quyền truy cập toàn hệ thống, tùy chỉnh tính năng và theo dõi nhật ký hoạt động.
          </p>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white border border-slate-200 p-6 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="p-3 bg-indigo-50 text-indigo-600 rounded-2xl border border-indigo-100">
            <Users size={26} />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">Tổng số Chủ nhà</p>
            <p className="text-2xl font-bold text-slate-800 mt-0.5">{totalManagers}</p>
          </div>
        </div>

        <div className="bg-white border border-slate-200 p-6 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="p-3 bg-emerald-50 text-emerald-600 rounded-2xl border border-emerald-100">
            <CheckCircle2 size={26} />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">Tài khoản Hoạt động</p>
            <p className="text-2xl font-bold text-slate-800 mt-0.5">{activeManagers}</p>
          </div>
        </div>

        <div className="bg-white border border-slate-200 p-6 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="p-3 bg-red-50 text-red-600 rounded-2xl border border-red-100">
            <Lock size={26} />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">Tài khoản Bị khóa</p>
            <p className="text-2xl font-bold text-slate-800 mt-0.5">{lockedManagers}</p>
          </div>
        </div>

        <div className="bg-white border border-slate-200 p-6 rounded-2xl flex items-center gap-4 shadow-sm">
          <div className="p-3 bg-sky-50 text-sky-600 rounded-2xl border border-sky-100">
            <Server size={26} />
          </div>
          <div>
            <p className="text-xs font-medium text-slate-500">Trạng thái Máy chủ</p>
            <p className="text-sm font-bold text-emerald-600 mt-1 flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Operational
            </p>
          </div>
        </div>
      </div>

      {/* Recent Managers Section */}
      <div className="bg-white border border-slate-200 rounded-2xl p-6 space-y-4 shadow-sm">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-bold text-slate-900 font-display">Chủ nhà đăng ký mới nhất</h2>
            <p className="text-xs text-slate-500">Danh sách tài khoản vừa đăng ký tham gia nền tảng</p>
          </div>
          <Link
            to="/admin/managers"
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-600 hover:text-indigo-800 transition-colors"
          >
            Xem tất cả <ArrowUpRight size={14} />
          </Link>
        </div>

        {loading ? (
          <div className="py-8 text-center text-slate-500 text-sm">Đang tải...</div>
        ) : (
          <div className="divide-y divide-slate-100">
            {managers.map(m => {
              const name = m.fullName || (m as any).name || "Chủ nhà";
              return (
                <div key={m.id} className="py-3.5 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-full bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center border border-indigo-200 text-sm">
                      {name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-slate-800">{name}</p>
                      <p className="text-xs text-slate-500">{m.email}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                      m.status === "LOCKED" ? "bg-red-50 text-red-700 border border-red-200" : "bg-emerald-50 text-emerald-700 border border-emerald-200"
                    }`}>
                      {m.status === "LOCKED" ? "Bị khóa" : "Hoạt động"}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

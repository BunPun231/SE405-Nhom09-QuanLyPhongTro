import { Link, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { 
  LayoutDashboard, 
  Users, 
  ShieldCheck, 
  FileText, 
  Settings, 
  LogOut
} from "lucide-react";
import { useAuthStore } from "@/store/authStore";

const SUPER_ADMIN_NAV = [
  { name: "Tổng quan SaaS", path: "/admin/dashboard", icon: LayoutDashboard },
  { name: "Quản lý Chủ nhà", path: "/admin/managers", icon: Users },
  { name: "Nhật ký hệ thống", path: "/admin/audit-logs", icon: FileText },
  { name: "Hồ sơ & Cài đặt", path: "/admin/settings", icon: Settings }
];

export function SuperAdminSidebar() {
  const location = useLocation();
  const { user, logout } = useAuthStore();

  return (
    <div className="flex h-screen w-64 flex-col border-r border-slate-200 bg-slate-50 text-slate-700">
      {/* Brand */}
      <div className="flex h-16 items-center gap-3 px-6 border-b border-slate-200 bg-white">
        <div className="p-2 bg-indigo-600 rounded-xl shadow-sm">
          <ShieldCheck size={22} className="text-white" />
        </div>
        <div>
          <h1 className="text-base font-bold text-slate-900 font-display">Super Admin</h1>
          <p className="text-xs text-indigo-600 font-medium">SmartBoarding Platform</p>
        </div>
      </div>
      
      {/* Navigation */}
      <div className="flex-1 overflow-y-auto py-4">
        <div className="px-4 mb-2">
          <p className="text-[11px] font-semibold tracking-wider text-slate-400 uppercase">Quản trị hệ thống</p>
        </div>
        <nav className="space-y-1 px-3">
          {SUPER_ADMIN_NAV.map((item) => {
            const isActive = location.pathname === item.path || (item.path !== "/admin/dashboard" && location.pathname.startsWith(item.path));
            return (
              <Link
                key={item.name}
                to={item.path}
                className={cn(
                  "flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-medium transition-all",
                  isActive
                    ? "bg-indigo-600 text-white shadow-md shadow-indigo-600/20"
                    : "text-slate-600 hover:bg-slate-200/70 hover:text-slate-900"
                )}
              >
                <item.icon className="h-5 w-5" />
                {item.name}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* User profile & Logout */}
      <div className="border-t border-slate-200 p-4 bg-white">
        <div className="flex items-center gap-3 mb-3 bg-slate-50 p-2.5 rounded-xl border border-slate-200">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-indigo-600 text-white font-bold text-xs uppercase flex-shrink-0">
            {user?.name?.charAt(0) || "A"}
          </div>
          <div className="flex flex-col min-w-0">
            <span className="text-xs font-semibold text-slate-900 truncate">{user?.name || "Super Admin"}</span>
            <span className="text-[11px] text-indigo-600 font-medium">Platform Admin</span>
          </div>
        </div>
        <button 
          onClick={logout}
          className="flex w-full items-center gap-3 rounded-xl px-3.5 py-2 text-sm font-medium text-slate-600 hover:bg-red-50 hover:text-red-600 transition-colors"
        >
          <LogOut className="h-5 w-5" />
          Đăng xuất
        </button>
      </div>
    </div>
  );
}

import { useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { 
  LayoutDashboard, 
  Building2, 
  Users, 
  FileText, 
  Receipt, 
  Settings, 
  Gauge, 
  BarChart3,
  LogOut,
  Layers
} from "lucide-react";
import { useAuthStore } from "@/store/authStore";
import { useWorkspaceStore } from "@/store/workspaceStore";

const NAV_ITEMS = [
  { key: "dashboard", name: "Tổng quan", path: "/dashboard", icon: LayoutDashboard },
  { key: "motels", name: "Khu trọ & Phòng", path: "/motels", icon: Building2 },
  { key: "services", name: "Dịch vụ", path: "/services", icon: Settings },
  { key: "residents", name: "Khách thuê", path: "/residents", icon: Users },
  { key: "contracts", name: "Hợp đồng & Cọc", path: "/contracts", icon: FileText },
  { key: "meter", name: "Ghi chỉ số", path: "/meter", icon: Gauge },
  { key: "invoices", name: "Hóa đơn", path: "/invoices", icon: Receipt },
  { key: "reports", name: "Thống kê", path: "/reports", icon: BarChart3 },
  { key: "auditLog", name: "Nhật ký", path: "/audit-log", icon: Layers },
  { key: "settings", name: "Cấu hình", path: "/settings", icon: Settings }
];

export function Sidebar() {
  const location = useLocation();
  const { user, logout } = useAuthStore();
  const { modules, fetchConfig } = useWorkspaceStore();

  const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";
  const isManager = (user?.role as string) === "MANAGER";

  useEffect(() => {
    if (isManager) {
      fetchConfig();
    }
  }, [isManager]);

  // Filter NAV_ITEMS based on role and workspace customization (UC17)
  const filteredItems = NAV_ITEMS.filter((item) => {
    if (isTenant) {
      return ["/dashboard", "/invoices", "/settings", "/meter"].includes(item.path);
    }
    if (isManager) {
      // Always show Dashboard and Settings
      if (item.key === "dashboard" || item.key === "settings") return true;
      // Respect workspace module configuration (UC17)
      return modules[item.key] !== false;
    }
    return true;
  }).map((item) => {
    if (isTenant && item.path === "/invoices") {
      return { ...item, name: "Hóa đơn của tôi" };
    }
    if (isTenant && item.path === "/meter") {
      return { ...item, name: "Ghi chỉ số điện nước" };
    }
    return item;
  });

  const getRoleLabel = (role?: string) => {
    switch (role) {
      case "ADMIN":
        return "Super Admin";
      case "MANAGER":
        return "Quản lý";
      case "TENANT":
        return "Khách thuê";
      case "TECHNICIAN":
        return "Kỹ thuật viên";
      default:
        return "Người dùng";
    }
  };

  return (
    <div className="flex h-screen w-64 flex-col border-r border-slate-200 bg-slate-50">
      <div className="flex h-16 items-center px-6">
        <h1 className="text-xl font-bold text-brand-ink font-display">Smart Boarding</h1>
      </div>
      
      <div className="flex-1 overflow-y-auto py-4">
        <nav className="space-y-1 px-3">
          {filteredItems.map((item) => {
            const isActive = location.pathname.startsWith(item.path);
            return (
              <Link
                key={item.name}
                id={
                  item.path === "/residents"
                    ? "sidebar-residents"
                    : item.path === "/services"
                    ? "sidebar-services"
                    : undefined
                }
                to={item.path}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                  isActive
                    ? "bg-brand-deep text-white"
                    : "text-slate-600 hover:bg-slate-200 hover:text-slate-900"
                )}
              >
                <item.icon className="h-5 w-5" />
                {item.name}
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="border-t border-slate-200 p-4">
        <div className="flex items-center gap-3 mb-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-brand-warm text-white font-bold uppercase">
            {user?.name?.charAt(0) || "U"}
          </div>
          <div className="flex flex-col min-w-0">
            <span className="text-sm font-semibold text-slate-800 truncate">{user?.name}</span>
            <span className="text-xs text-slate-500">{getRoleLabel(user?.role)}</span>
          </div>
        </div>
        <button 
          onClick={logout}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-200 hover:text-slate-900 transition-colors"
        >
          <LogOut className="h-5 w-5" />
          Đăng xuất
        </button>
      </div>
    </div>
  );
}

import { Search } from "lucide-react";
import { useAuthStore } from "@/store/authStore";
import { NotificationBell } from "./NotificationBell";

export function Header() {
  const { user } = useAuthStore();

  const getRoleLabel = (role?: string) => {
    switch (role) {
      case "ADMIN":
        return "Admin";
      case "MANAGER":
        return "Quản lý";
      case "TENANT":
      case "RESIDENT":
        return "Khách thuê";
      case "TECHNICIAN":
        return "Kỹ thuật viên";
      default:
        return "Người dùng";
    }
  };

  return (
    <header className="flex h-16 items-center justify-between border-b border-slate-200 bg-white px-6">
      <div className="flex flex-1 items-center gap-4">
        <div className="relative w-96">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input 
            type="text"
            placeholder="Tìm kiếm..." 
            className="h-10 w-full rounded-full border border-slate-200 bg-slate-50 pl-10 pr-4 text-sm focus:border-brand-deep focus:outline-none focus:ring-1 focus:ring-brand-deep"
          />
        </div>
      </div>
      <div className="flex items-center gap-4">
        <NotificationBell />
        <div className="text-sm font-medium text-slate-600 border border-slate-200 rounded-lg px-3 py-1.5 bg-slate-50">
          Vai trò: {getRoleLabel(user?.role)}
        </div>
      </div>
    </header>
  );
}

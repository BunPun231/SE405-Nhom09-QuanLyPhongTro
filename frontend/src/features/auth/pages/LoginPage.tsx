import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { useAuthStore } from "@/store/authStore";
import { useTenantStore } from "@/store/tenantStore";
import { authService } from "@/services/authService";
import { extractError } from "@/lib/api";
import { Building2, Lock, Phone, Eye, EyeOff } from "lucide-react";

export function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuthStore();
  const { setTenantId } = useTenantStore();

  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [showPwd, setShowPwd] = useState(false);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);

    try {
      const result = await authService.login({ identity: phone, password });

      if (!result) {
        throw new Error("Phản hồi từ máy chủ không hợp lệ (Không có dữ liệu).");
      }

      // Store tenant if present
      if (result.tenantId) {
        setTenantId(result.tenantId);
      }

      // Login with token and user
      login(result.accessToken, {
        id: result.userId,
        name: result.fullName,
        email: "",
        phone: phone, // We know the phone because they used it to login
        role: result.role as "ADMIN" | "MANAGER" | "TENANT" | "TECHNICIAN",
        hasCompletedOnboarding: result.hasCompletedOnboarding,
      });

      navigate("/dashboard");
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-gradient-to-br from-slate-900 to-brand-deep">
      {/* Left side - Branding */}
      <div className="hidden lg:flex w-1/2 flex-col justify-center p-16 relative overflow-hidden">
        {/* Background decoration */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full bg-white/20 blur-3xl" />
          <div className="absolute -bottom-32 -right-32 w-96 h-96 rounded-full bg-brand-sand/30 blur-3xl" />
        </div>

        <div className="relative z-10">
          {/* Logo */}
          <div className="flex items-center gap-3 mb-12">
            <div className="p-3 bg-white/15 rounded-2xl backdrop-blur">
              <Building2 size={32} className="text-white" />
            </div>
            <div>
              <span className="text-white font-bold text-2xl font-display block leading-none">
                Smart<span className="text-brand-sand">Boarding</span>
              </span>
              <span className="text-white/60 text-xs tracking-widest uppercase">Rental Management</span>
            </div>
          </div>

          <h1 className="text-5xl font-bold text-white font-display leading-tight mb-6">
            Quản lý nhà trọ<br />
            <span className="text-brand-sand">thông minh</span>
          </h1>
          <p className="text-white/70 text-lg leading-relaxed max-w-md">
            Tối ưu hóa doanh thu, tự động hóa quy trình thu tiền, và quản lý toàn bộ bất động sản trong một nền tảng duy nhất.
          </p>

          {/* Stats */}
          <div className="mt-12 grid grid-cols-3 gap-6">
            {[
              { label: "Khu trọ", value: "1,200+" },
              { label: "Phòng quản lý", value: "18,000+" },
              { label: "Hóa đơn/tháng", value: "50,000+" },
            ].map((stat) => (
              <div key={stat.label} className="bg-white/10 rounded-2xl p-4 backdrop-blur">
                <div className="text-2xl font-bold text-white font-display">{stat.value}</div>
                <div className="text-white/60 text-sm mt-1">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right side - Login Form */}
      <div className="flex w-full lg:w-1/2 flex-col justify-center bg-white px-8 xl:px-16">
        <div className="mx-auto w-full max-w-md">
          {/* Mobile logo */}
          <div className="flex items-center gap-2 mb-8 lg:hidden">
            <Building2 size={28} className="text-brand-deep" />
            <span className="font-bold text-xl font-display text-brand-ink">SmartBoarding</span>
          </div>

          <div className="mb-8">
            <h2 className="font-display text-3xl font-bold text-brand-ink mb-2">Đăng nhập</h2>
            <p className="text-slate-500">Chào mừng trở lại! Vui lòng đăng nhập để tiếp tục.</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {error && (
              <div className="rounded-xl bg-red-50 border border-red-100 p-4 text-sm text-red-700 flex items-start gap-3">
                <Lock size={16} className="mt-0.5 flex-shrink-0" />
                {error}
              </div>
            )}

            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Số điện thoại</label>
              <div className="relative">
                <Phone size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  id="login-phone"
                  type="tel"
                  placeholder="0912 345 678"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  required
                  className="w-full pl-12 pr-4 py-3 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all text-sm"
                />
              </div>
            </div>

            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Mật khẩu</label>
              <div className="relative">
                <Lock size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  id="login-password"
                  type={showPwd ? "text" : "password"}
                  placeholder="Nhập mật khẩu"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="w-full pl-12 pr-12 py-3 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all text-sm"
                />
                <button
                  type="button"
                  onClick={() => setShowPwd(!showPwd)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showPwd ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 text-sm text-slate-600 cursor-pointer">
                <input
                  id="login-remember"
                  type="checkbox"
                  className="rounded border-slate-300 text-brand-deep focus:ring-brand-deep"
                />
                Ghi nhớ đăng nhập
              </label>
              <Link
                to="/forgot-password"
                className="text-sm font-medium text-brand-deep hover:text-brand-deep/80 hover:underline transition-colors"
              >
                Quên mật khẩu?
              </Link>
            </div>

            <button
              id="login-submit"
              type="submit"
              disabled={isLoading}
              className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 active:scale-[0.98] transition-all disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-sm shadow-brand-deep/30"
            >
              {isLoading ? (
                <>
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  Đang xử lý...
                </>
              ) : "Đăng nhập"}
            </button>
          </form>

          <p className="mt-8 text-center text-sm text-slate-500">
            Chưa có tài khoản?{" "}
            <Link to="/register" className="font-semibold text-brand-deep hover:underline">
              Đăng ký miễn phí
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}

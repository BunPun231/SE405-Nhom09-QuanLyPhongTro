import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Building2, User, Phone, Mail, Lock, Eye, EyeOff, CheckCircle2 } from "lucide-react";
import { authService } from "@/services/authService";
import { extractError } from "@/lib/api";

export function RegisterPage() {
  const navigate = useNavigate();

  const [form, setForm] = useState({
    tenantName: "",
    fullName: "",
    phone: "",
    email: "",
    password: "",
    confirmPassword: "",
  });
  const [showPwd, setShowPwd] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  const passwordsMatch = form.password === form.confirmPassword;
  const isPasswordStrong = form.password.length >= 8;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!passwordsMatch) {
      setError("Mật khẩu xác nhận không khớp");
      return;
    }
    if (!isPasswordStrong) {
      setError("Mật khẩu phải có ít nhất 8 ký tự");
      return;
    }

    setError("");
    setIsLoading(true);
    try {
      await authService.register({
        tenantName: form.fullName + " Workspace",
        phone: form.phone,
        email: form.email || undefined,
        fullName: form.fullName,
        password: form.password,
      });
      setSuccess(true);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-3 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <div className="flex min-h-screen bg-gradient-to-br from-slate-900 to-brand-deep">
      {/* Left side branding */}
      <div className="hidden lg:flex w-1/2 flex-col justify-center p-16 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full bg-white/20 blur-3xl" />
          <div className="absolute -bottom-32 -right-32 w-96 h-96 rounded-full bg-brand-sand/30 blur-3xl" />
        </div>
        <div className="relative z-10">
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
          <h1 className="text-4xl font-bold text-white font-display leading-tight mb-6">
            Bắt đầu hành trình<br />
            <span className="text-brand-sand">quản lý chuyên nghiệp</span>
          </h1>
          <p className="text-white/70 text-lg leading-relaxed max-w-md">
            Đăng ký miễn phí và trải nghiệm đầy đủ tính năng trong 30 ngày đầu.
          </p>
          <div className="mt-10 space-y-3">
            {[
              "Quản lý không giới hạn phòng trong 30 ngày",
              "Tự động tạo hóa đơn hàng tháng",
              "Báo cáo doanh thu chi tiết",
              "Hỗ trợ kỹ thuật 24/7",
            ].map((feature) => (
              <div key={feature} className="flex items-center gap-3 text-white/80">
                <CheckCircle2 size={18} className="text-brand-sand flex-shrink-0" />
                <span className="text-sm">{feature}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Right side form */}
      <div className="flex w-full lg:w-1/2 flex-col justify-center bg-white px-8 xl:px-16 py-12 overflow-y-auto">
        <div className="mx-auto w-full max-w-md">
          {/* Mobile logo */}
          <div className="flex items-center gap-2 mb-8 lg:hidden">
            <Building2 size={28} className="text-brand-deep" />
            <span className="font-bold text-xl font-display text-brand-ink">SmartBoarding</span>
          </div>

          {success ? (
            <div className="text-center py-8">
              <div className="p-5 bg-emerald-50 rounded-2xl inline-block mb-5">
                <CheckCircle2 size={40} className="text-emerald-500" />
              </div>
              <h2 className="font-display text-2xl font-bold text-brand-ink mb-2">Đăng ký thành công!</h2>
              <p className="text-slate-500 mb-6">
                Tài khoản của bạn đã được tạo. Vui lòng đăng nhập để tiếp tục.
              </p>
              <button
                onClick={() => navigate("/login")}
                className="w-full py-3 bg-brand-deep text-white rounded-xl font-semibold hover:bg-brand-deep/90 transition-colors"
              >
                Đăng nhập ngay
              </button>
            </div>
          ) : (
            <>
              <div className="mb-8">
                <h2 className="font-display text-3xl font-bold text-brand-ink mb-2">Tạo tài khoản</h2>
                <p className="text-slate-500">Điền thông tin để bắt đầu sử dụng SmartBoarding</p>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
                    {error}
                  </div>
                )}

                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Họ và tên *</label>
                  <div className="relative">
                    <User size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="register-fullname"
                      type="text"
                      value={form.fullName}
                      onChange={(e) => setForm({ ...form, fullName: e.target.value })}
                      placeholder="Nguyễn Văn An"
                      required
                      className={`${inputClass} pl-12`}
                    />
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Số điện thoại *</label>
                  <div className="relative">
                    <Phone size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="register-phone"
                      type="tel"
                      value={form.phone}
                      onChange={(e) => setForm({ ...form, phone: e.target.value })}
                      placeholder="0912 345 678"
                      required
                      className={`${inputClass} pl-12`}
                    />
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Email</label>
                  <div className="relative">
                    <Mail size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="register-email"
                      type="email"
                      value={form.email}
                      onChange={(e) => setForm({ ...form, email: e.target.value })}
                      placeholder="example@gmail.com (tùy chọn)"
                      className={`${inputClass} pl-12`}
                    />
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Mật khẩu *</label>
                  <div className="relative">
                    <Lock size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="register-password"
                      type={showPwd ? "text" : "password"}
                      value={form.password}
                      onChange={(e) => setForm({ ...form, password: e.target.value })}
                      placeholder="Tối thiểu 8 ký tự"
                      required
                      className={`${inputClass} pl-12 pr-12`}
                    />
                    <button type="button" onClick={() => setShowPwd(!showPwd)}
                      className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                      {showPwd ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                  {form.password && (
                    <div className="flex items-center gap-2 mt-1">
                      <div className={`h-1 flex-1 rounded-full ${isPasswordStrong ? "bg-emerald-400" : "bg-red-300"}`} />
                      <span className={`text-xs ${isPasswordStrong ? "text-emerald-600" : "text-red-500"}`}>
                        {isPasswordStrong ? "Đủ mạnh" : "Quá ngắn"}
                      </span>
                    </div>
                  )}
                </div>

                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Xác nhận mật khẩu *</label>
                  <div className="relative">
                    <Lock size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="register-confirm"
                      type={showConfirm ? "text" : "password"}
                      value={form.confirmPassword}
                      onChange={(e) => setForm({ ...form, confirmPassword: e.target.value })}
                      placeholder="Nhập lại mật khẩu"
                      required
                      className={`${inputClass} pl-12 pr-12 ${form.confirmPassword && !passwordsMatch ? "border-red-300 focus:ring-red-200 focus:border-red-400" : ""}`}
                    />
                    <button type="button" onClick={() => setShowConfirm(!showConfirm)}
                      className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                      {showConfirm ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                  {form.confirmPassword && !passwordsMatch && (
                    <p className="text-xs text-red-500 mt-1">Mật khẩu không khớp</p>
                  )}
                </div>

                <button
                  id="register-submit"
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 active:scale-[0.98] transition-all disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-sm shadow-brand-deep/30 mt-2"
                >
                  {isLoading ? (
                    <>
                      <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                      </svg>
                      Đang tạo tài khoản...
                    </>
                  ) : "Đăng ký tài khoản"}
                </button>
              </form>

              <p className="mt-6 text-center text-sm text-slate-500">
                Đã có tài khoản?{" "}
                <Link to="/login" className="font-semibold text-brand-deep hover:underline">
                  Đăng nhập
                </Link>
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

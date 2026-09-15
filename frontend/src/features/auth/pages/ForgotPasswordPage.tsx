import { useState } from "react";
import { Link } from "react-router-dom";
import { Building2, Mail, ArrowLeft, CheckCircle2, Send } from "lucide-react";
import { authService } from "@/services/authService";
import { extractError } from "@/lib/api";

export function ForgotPasswordPage() {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isSent, setIsSent] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);
    try {
      await authService.forgotPassword({ identity: email });
      setIsSent(true);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  const [otp, setOtp] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isResetSuccess, setIsResetSuccess] = useState(false);

  const handleResetSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setError("Mật khẩu xác nhận không khớp");
      return;
    }
    setError("");
    setIsLoading(true);
    try {
      await authService.resetPassword({
        identity: email,
        otp,
        newPassword,
        confirmPassword
      });
      setIsResetSuccess(true);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-3 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-slate-50 to-slate-100 p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="flex items-center justify-center gap-2 mb-8">
          <div className="p-2.5 bg-brand-deep rounded-xl">
            <Building2 size={24} className="text-white" />
          </div>
          <span className="font-bold text-xl font-display text-brand-ink">SmartBoarding</span>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-8">
          {!isSent ? (
            <>
              <div className="text-center mb-8">
                <div className="p-4 bg-brand-deep/10 rounded-2xl inline-block mb-4">
                  <Mail size={32} className="text-brand-deep" />
                </div>
                <h1 className="font-display text-2xl font-bold text-brand-ink mb-2">Quên mật khẩu?</h1>
                <p className="text-slate-500 text-sm">
                  Nhập email đăng ký của bạn. Chúng tôi sẽ gửi liên kết đặt lại mật khẩu.
                </p>
              </div>

              {error && (
                <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700 mb-4">
                  {error}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Địa chỉ email</label>
                  <div className="relative">
                    <Mail size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="forgot-email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="email@example.com"
                      required
                      className={`${inputClass} pl-12`}
                    />
                  </div>
                </div>

                <button
                  id="forgot-submit"
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 active:scale-[0.98] transition-all disabled:opacity-60 flex items-center justify-center gap-2"
                >
                  {isLoading ? (
                    <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                  ) : <Send size={16} />}
                  {isLoading ? "Đang gửi..." : "Gửi liên kết đặt lại"}
                </button>
              </form>
            </>
          ) : (
            <div>
              {isResetSuccess ? (
                <div className="text-center py-4">
                  <div className="p-5 bg-emerald-50 rounded-2xl inline-block mb-5">
                    <CheckCircle2 size={40} className="text-emerald-500" />
                  </div>
                  <h2 className="font-display text-2xl font-bold text-brand-ink mb-2">Đổi mật khẩu thành công!</h2>
                  <p className="text-slate-500 text-sm mb-6">
                    Mật khẩu của bạn đã được đặt lại. Vui lòng đăng nhập bằng mật khẩu mới.
                  </p>
                  <Link
                    to="/login"
                    className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 flex items-center justify-center"
                  >
                    Đăng nhập ngay
                  </Link>
                </div>
              ) : (
                <>
                  <div className="text-center mb-6">
                    <div className="p-4 bg-emerald-50 rounded-2xl inline-block mb-4">
                      <CheckCircle2 size={32} className="text-emerald-500" />
                    </div>
                    <h2 className="font-display text-xl font-bold text-brand-ink mb-2">Kiểm tra email / điện thoại</h2>
                    <p className="text-slate-500 text-sm">
                      Chúng tôi đã gửi mã xác thực (OTP) đến: <br/><span className="font-semibold text-brand-deep">{email}</span>
                    </p>
                  </div>
                  
                  {error && (
                    <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700 mb-4">
                      {error}
                    </div>
                  )}

                  <form onSubmit={handleResetSubmit} className="space-y-4">
                    <div className="space-y-1">
                      <label className="text-sm font-medium text-slate-700">Mã xác thực (OTP)</label>
                      <input
                        type="text"
                        value={otp}
                        onChange={(e) => setOtp(e.target.value)}
                        placeholder="Nhập mã OTP"
                        required
                        className={inputClass}
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-sm font-medium text-slate-700">Mật khẩu mới</label>
                      <input
                        type="password"
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        placeholder="Tối thiểu 8 ký tự"
                        required
                        className={inputClass}
                      />
                    </div>
                    <div className="space-y-1">
                      <label className="text-sm font-medium text-slate-700">Xác nhận mật khẩu</label>
                      <input
                        type="password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Nhập lại mật khẩu mới"
                        required
                        className={inputClass}
                      />
                    </div>
                    <button
                      type="submit"
                      disabled={isLoading}
                      className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 active:scale-[0.98] transition-all disabled:opacity-60"
                    >
                      {isLoading ? "Đang xử lý..." : "Đặt lại mật khẩu"}
                    </button>
                  </form>
                  <button
                    onClick={() => { setIsSent(false); setError(""); }}
                    className="w-full mt-4 text-sm text-brand-deep font-medium hover:underline text-center"
                  >
                    Sử dụng email/sdt khác
                  </button>
                </>
              )}
            </div>
          )}

          <div className="mt-6 pt-4 border-t border-slate-100 text-center">
            <Link
              to="/login"
              className="inline-flex items-center gap-2 text-sm font-medium text-slate-500 hover:text-brand-deep transition-colors"
            >
              <ArrowLeft size={14} />
              Quay lại đăng nhập
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

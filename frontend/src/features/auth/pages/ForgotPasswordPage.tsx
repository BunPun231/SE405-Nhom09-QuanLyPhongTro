import { useState } from "react";
import { Link } from "react-router-dom";
import { Building2, Mail, ArrowLeft, CheckCircle2, Send, ShieldCheck, KeyRound, Eye, EyeOff, Smartphone } from "lucide-react";
import { authService } from "@/services/authService";
import { extractError } from "@/lib/api";

type Step = 1 | 2 | 3 | 4; // 1: Identity, 2: OTP, 3: New Password, 4: Success

export function ForgotPasswordPage() {
  const [step, setStep] = useState<Step>(1);
  const [identity, setIdentity] = useState("");
  const [otp, setOtp] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  
  const [showNewPwd, setShowNewPwd] = useState(false);
  const [showConfirmPwd, setShowConfirmPwd] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  // Step 1: Send OTP
  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (!identity.trim()) {
      setError("Vui lòng nhập Email hoặc Số điện thoại");
      return;
    }
    setIsLoading(true);
    try {
      await authService.forgotPassword({ identity: identity.trim() });
      setStep(2);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  // Step 2: Submit OTP and advance to password step
  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    if (!otp.trim() || otp.trim().length < 4) {
      setError("Vui lòng nhập đầy đủ mã OTP");
      return;
    }
    setIsLoading(true);
    try {
      await authService.verifyOtp({ identity: identity.trim(), otp: otp.trim() });
      setStep(3);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  // Step 3: Reset password
  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (newPassword !== confirmPassword) {
      setError("Mật khẩu xác nhận không khớp");
      return;
    }
    if (newPassword.length < 8) {
      setError("Mật khẩu mới phải từ 8 ký tự trở lên");
      return;
    }
    setError("");
    setIsLoading(true);
    try {
      await authService.resetPassword({
        identity: identity.trim(),
        otp: otp.trim(),
        newPassword,
        confirmPassword
      });
      setStep(4);
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
          {/* Progress Indicator */}
          {step < 4 && (
            <div className="flex items-center justify-between mb-8 px-4">
              <div className={`flex items-center justify-center w-8 h-8 rounded-full text-xs font-bold ${
                step >= 1 ? "bg-brand-deep text-white" : "bg-slate-100 text-slate-400"
              }`}>1</div>
              <div className={`flex-1 h-0.5 mx-2 ${step >= 2 ? "bg-brand-deep" : "bg-slate-200"}`} />
              <div className={`flex items-center justify-center w-8 h-8 rounded-full text-xs font-bold ${
                step >= 2 ? "bg-brand-deep text-white" : "bg-slate-100 text-slate-400"
              }`}>2</div>
              <div className={`flex-1 h-0.5 mx-2 ${step >= 3 ? "bg-brand-deep" : "bg-slate-200"}`} />
              <div className={`flex items-center justify-center w-8 h-8 rounded-full text-xs font-bold ${
                step >= 3 ? "bg-brand-deep text-white" : "bg-slate-100 text-slate-400"
              }`}>3</div>
            </div>
          )}

          {error && (
            <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700 mb-4">
              {error}
            </div>
          )}

          {/* STEP 1: Enter Email / Phone */}
          {step === 1 && (
            <>
              <div className="text-center mb-8">
                <div className="p-4 bg-brand-deep/10 rounded-2xl inline-block mb-4">
                  <Mail size={32} className="text-brand-deep" />
                </div>
                <h1 className="font-display text-2xl font-bold text-brand-ink mb-2">Quên mật khẩu?</h1>
                <p className="text-slate-500 text-sm">
                  Nhập Email hoặc Số điện thoại đăng ký của bạn. Chúng tôi sẽ gửi mã OTP xác thực.
                </p>
              </div>

              <form onSubmit={handleSendOtp} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Email hoặc Số điện thoại</label>
                  <div className="relative">
                    <Smartphone size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="forgot-identity"
                      type="text"
                      value={identity}
                      onChange={(e) => setIdentity(e.target.value)}
                      placeholder="email@example.com hoặc 0912345678"
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
                  {isLoading ? "Đang gửi OTP..." : "Gửi mã OTP"}
                </button>
              </form>
            </>
          )}

          {/* STEP 2: Enter OTP */}
          {step === 2 && (
            <>
              <div className="text-center mb-8">
                <div className="p-4 bg-amber-50 rounded-2xl inline-block mb-4">
                  <ShieldCheck size={32} className="text-amber-600" />
                </div>
                <h2 className="font-display text-2xl font-bold text-brand-ink mb-2">Nhập mã xác thực (OTP)</h2>
                <p className="text-slate-500 text-sm">
                  Chúng tôi đã gửi mã OTP đến: <br/>
                  <span className="font-semibold text-brand-deep">{identity}</span>
                </p>
              </div>

              <form onSubmit={handleVerifyOtp} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Mã xác thực OTP (6 số)</label>
                  <div className="relative">
                    <KeyRound size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      id="forgot-otp"
                      type="text"
                      maxLength={6}
                      value={otp}
                      onChange={(e) => setOtp(e.target.value)}
                      placeholder="123456"
                      required
                      className={`${inputClass} pl-12 tracking-widest text-lg font-bold text-center`}
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 active:scale-[0.98] transition-all flex items-center justify-center gap-2"
                >
                  Tiếp tục đặt mật khẩu mới
                </button>
              </form>

              <button
                onClick={() => { setStep(1); setError(""); }}
                className="w-full mt-4 text-sm text-slate-500 font-medium hover:underline text-center"
              >
                Nhập lại Email / SĐT khác
              </button>
            </>
          )}

          {/* STEP 3: Enter New Password */}
          {step === 3 && (
            <>
              <div className="text-center mb-8">
                <div className="p-4 bg-indigo-50 rounded-2xl inline-block mb-4">
                  <KeyRound size={32} className="text-indigo-600" />
                </div>
                <h2 className="font-display text-2xl font-bold text-brand-ink mb-2">Đặt mật khẩu mới</h2>
                <p className="text-slate-500 text-sm">
                  Vui lòng tạo mật khẩu mới an toàn cho tài khoản của bạn.
                </p>
              </div>

              <form onSubmit={handleResetPassword} className="space-y-4">
                {/* New Password */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Mật khẩu mới</label>
                  <div className="relative">
                    <input
                      id="forgot-new-pwd"
                      type={showNewPwd ? "text" : "password"}
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="Tối thiểu 8 ký tự"
                      required
                      className={`${inputClass} pr-12`}
                    />
                    <button
                      type="button"
                      onClick={() => setShowNewPwd(!showNewPwd)}
                      className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors p-1"
                    >
                      {showNewPwd ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>

                {/* Confirm Password */}
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Xác nhận mật khẩu mới</label>
                  <div className="relative">
                    <input
                      id="forgot-confirm-pwd"
                      type={showConfirmPwd ? "text" : "password"}
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Nhập lại mật khẩu mới"
                      required
                      className={`${inputClass} pr-12`}
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirmPwd(!showConfirmPwd)}
                      className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors p-1"
                    >
                      {showConfirmPwd ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>

                {newPassword && confirmPassword && newPassword !== confirmPassword && (
                  <p className="text-xs text-red-500 font-medium">Mật khẩu xác nhận không khớp</p>
                )}

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 active:scale-[0.98] transition-all disabled:opacity-60 flex items-center justify-center gap-2"
                >
                  {isLoading ? "Đang xử lý..." : "Hoàn tất đặt lại mật khẩu"}
                </button>
              </form>

              <button
                onClick={() => { setStep(2); setError(""); }}
                className="w-full mt-4 text-sm text-slate-500 font-medium hover:underline text-center"
              >
                Quay lại bước nhập OTP
              </button>
            </>
          )}

          {/* STEP 4: Success */}
          {step === 4 && (
            <div className="text-center py-4">
              <div className="p-5 bg-emerald-50 rounded-2xl inline-block mb-5">
                <CheckCircle2 size={40} className="text-emerald-500" />
              </div>
              <h2 className="font-display text-2xl font-bold text-brand-ink mb-2">Đổi mật khẩu thành công!</h2>
              <p className="text-slate-500 text-sm mb-6">
                Mật khẩu của bạn đã được cập nhật thành công. Vui lòng đăng nhập bằng mật khẩu mới.
              </p>
              <Link
                to="/login"
                className="w-full py-3 px-6 bg-brand-deep text-white rounded-xl font-semibold text-sm hover:bg-brand-deep/90 flex items-center justify-center"
              >
                Đăng nhập ngay
              </Link>
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

import { useState } from "react";
import { Save, Shield, Bell, CreditCard, Building, User, Eye, EyeOff, CheckCircle2, AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { useAuthStore } from "@/store/authStore";
import { authService } from "@/services/authService";
import { extractError } from "@/lib/api";

// ============ CHANGE PASSWORD SECTION ============
function ChangePasswordSection() {
  const [form, setForm] = useState({ currentPassword: "", newPassword: "", confirmPassword: "" });
  const [showPwd, setShowPwd] = useState({ current: false, new: false, confirm: false });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  const passwordsMatch = form.newPassword === form.confirmPassword;
  const isStrong = form.newPassword.length >= 8;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!passwordsMatch) { setError("Mật khẩu mới không khớp"); return; }
    if (!isStrong) { setError("Mật khẩu mới phải có ít nhất 8 ký tự"); return; }
    setError("");
    setLoading(true);
    try {
      await authService.changePassword({
        oldPassword: form.currentPassword,
        newPassword: form.newPassword,
        confirmPassword: form.confirmPassword,
      });
      setSuccess(true);
      setForm({ currentPassword: "", newPassword: "", confirmPassword: "" });
      setTimeout(() => setSuccess(false), 4000);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all pr-12";

  const PwdField = ({
    id, label, field, value, placeholder,
  }: { id: string; label: string; field: "current" | "new" | "confirm"; value: string; placeholder: string }) => (
    <div className="space-y-1">
      <label className="text-sm font-medium text-slate-700">{label}</label>
      <div className="relative">
        <input
          id={id}
          type={showPwd[field] ? "text" : "password"}
          value={value}
          onChange={(e) => setForm({ ...form, [field === "current" ? "currentPassword" : field === "new" ? "newPassword" : "confirmPassword"]: e.target.value })}
          placeholder={placeholder}
          required
          className={inputClass}
        />
        <button
          type="button"
          onClick={() => setShowPwd({ ...showPwd, [field]: !showPwd[field] })}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
        >
          {showPwd[field] ? <EyeOff size={16} /> : <Eye size={16} />}
        </button>
      </div>
    </div>
  );

  return (
    <div className="space-y-6 max-w-lg">
      <h2 className="text-base font-bold text-brand-ink border-b border-slate-100 pb-3">Đổi mật khẩu (UC05)</h2>

      {success && (
        <div className="flex items-center gap-3 rounded-xl bg-emerald-50 border border-emerald-100 p-4 text-emerald-700">
          <CheckCircle2 size={18} />
          <span className="text-sm font-medium">Mật khẩu đã được cập nhật thành công!</span>
        </div>
      )}
      {error && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 border border-red-100 p-4 text-red-700">
          <AlertCircle size={18} />
          <span className="text-sm">{error}</span>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <PwdField id="pwd-current" label="Mật khẩu hiện tại *" field="current" value={form.currentPassword} placeholder="Nhập mật khẩu hiện tại" />
        <PwdField id="pwd-new" label="Mật khẩu mới *" field="new" value={form.newPassword} placeholder="Tối thiểu 8 ký tự" />
        {form.newPassword && (
          <div className="flex items-center gap-2">
            <div className={`h-1 flex-1 rounded-full ${isStrong ? "bg-emerald-400" : "bg-red-300"}`} />
            <span className={`text-xs ${isStrong ? "text-emerald-600" : "text-red-500"}`}>
              {isStrong ? "Đủ mạnh" : "Quá ngắn"}
            </span>
          </div>
        )}
        <PwdField id="pwd-confirm" label="Xác nhận mật khẩu mới *" field="confirm" value={form.confirmPassword} placeholder="Nhập lại mật khẩu mới" />
        {form.confirmPassword && !passwordsMatch && (
          <p className="text-xs text-red-500">Mật khẩu không khớp</p>
        )}
        <Button
          id="change-password-submit"
          type="submit"
          disabled={loading || !passwordsMatch || !isStrong}
        >
          {loading ? "Đang cập nhật..." : "Cập nhật mật khẩu"}
        </Button>
      </form>
    </div>
  );
}

// ============ MAIN SETTINGS PAGE ============
const TABS = [
  { id: "profile", label: "Hồ sơ", icon: User },
  { id: "security", label: "Bảo mật", icon: Shield },
] as const;

type TabId = "profile" | "security";

export function SettingsPage() {
  const { user, setUser } = useAuthStore();
  const [activeTab, setActiveTab] = useState<TabId>("profile");
  const [isSaving, setIsSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  const [name, setName] = useState(user?.name || "");
  const [phone, setPhone] = useState(user?.phone || "");
  const [email, setEmail] = useState(user?.email || "");

  const handleSave = () => {
    setIsSaving(true);
    setError("");
    setSuccess(false);
    try {
      if (user) {
        setUser({
          ...user,
          name,
          phone,
          email,
        });
      }
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      setError("Không thể lưu thay đổi.");
    } finally {
      setIsSaving(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";
  const areaClass = `${inputClass} resize-none`;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Cài đặt</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý tài khoản và cấu hình hệ thống</p>
        </div>
        {activeTab !== "security" && (
          <Button onClick={handleSave} disabled={isSaving}>
            <Save size={16} className="mr-2" />
            {isSaving ? "Đang lưu..." : "Lưu thay đổi"}
          </Button>
        )}
      </div>

      {success && (
        <div className="flex items-center gap-3 rounded-xl bg-emerald-50 border border-emerald-100 p-4 text-emerald-700 max-w-lg">
          <CheckCircle2 size={18} />
          <span className="text-sm font-medium">Thay đổi thông tin hồ sơ đã được lưu thành công!</span>
        </div>
      )}
      {error && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 border border-red-100 p-4 text-red-700 max-w-lg">
          <AlertCircle size={18} />
          <span className="text-sm">{error}</span>
        </div>
      )}

      <div className="flex flex-col lg:flex-row gap-6">
        {/* Sidebar */}
        <div className="w-full lg:w-56 space-y-1">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              id={`settings-tab-${tab.id}`}
              onClick={() => setActiveTab(tab.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all ${
                activeTab === tab.id
                  ? "bg-white text-brand-deep shadow-sm border border-slate-200"
                  : "text-slate-600 hover:bg-slate-100"
              }`}
            >
              <tab.icon size={18} />
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="flex-1 bg-white rounded-2xl shadow-sm border border-slate-200 p-6 min-h-[400px]">
          {/* Profile Tab */}
          {activeTab === "profile" && (
            <div className="space-y-6 max-w-lg">
              <h2 className="text-base font-bold text-brand-ink border-b border-slate-100 pb-3">Thông tin cá nhân</h2>
              {/* Avatar */}
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-2xl bg-brand-deep flex items-center justify-center text-white font-bold text-2xl">
                  {user?.name?.charAt(0).toUpperCase() ?? "U"}
                </div>
                <div>
                  <p className="font-semibold text-brand-ink">{user?.name}</p>
                  <p className="text-sm text-slate-500 capitalize">{user?.role?.toLowerCase()}</p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Họ và tên</label>
                  <input
                    id="profile-name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className={inputClass}
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-slate-700">Số điện thoại</label>
                    <input
                      id="profile-phone"
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      className={inputClass}
                    />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-slate-700">Email</label>
                    <input
                      id="profile-email"
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className={inputClass}
                    />
                  </div>
                </div>
              </div>

              <div className="border-t border-slate-100 pt-6">
                <h3 className="text-sm font-bold text-brand-ink mb-4">Cấu hình hợp đồng mặc định</h3>
                <div className="space-y-4">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-slate-700">Tiền cọc mặc định (tháng)</label>
                    <input id="profile-deposit" type="number" defaultValue={1} min={1} max={6} className={inputClass} />
                  </div>
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-slate-700">Quy định trả phòng</label>
                    <textarea
                      id="profile-policy"
                      rows={3}
                      defaultValue="- Báo trước 30 ngày&#10;- Hoàn 100% tiền cọc nếu không vi phạm&#10;- Phạt 100% tiền cọc nếu vi phạm hợp đồng"
                      className={areaClass}
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Security Tab */}
          {activeTab === "security" && (
            <div className="space-y-8">
              <ChangePasswordSection />

              <div className="max-w-lg border-t border-slate-100 pt-6">
                <h2 className="text-base font-bold text-brand-ink pb-3">Phiên đăng nhập</h2>
                <div className="rounded-xl bg-slate-50 border border-slate-200 p-4 flex items-center justify-between">
                  <div>
                    <p className="font-medium text-slate-800 text-sm">Thiết bị hiện tại</p>
                    <p className="text-xs text-slate-500 mt-0.5">Trình duyệt web • Đăng nhập gần đây</p>
                  </div>
                  <span className="text-xs bg-emerald-100 text-emerald-700 px-2.5 py-1 rounded-full font-medium">Đang hoạt động</span>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

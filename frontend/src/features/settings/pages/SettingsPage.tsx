import { useState, useEffect } from "react";
import {
  Save,
  Shield,
  User,
  Sliders,
  Eye,
  EyeOff,
  CheckCircle2,
  AlertCircle,
  Building2,
  Users,
  FileText,
  Gauge,
  Receipt,
  BarChart3,
  Layers,
  Settings as SettingsIcon
} from "lucide-react";
import { Button } from "@/components/ui/Button";
import { useAuthStore } from "@/store/authStore";
import { useWorkspaceStore } from "@/store/workspaceStore";
import { userService } from "@/services/userService";
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
      <h2 className="text-base font-bold text-brand-ink border-b border-slate-100 pb-3">Đổi mật khẩu</h2>

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

// ============ WORKSPACE CONFIGURATION TAB (UC17) ============
function WorkspaceConfigSection() {
  const { modules, updateModules, fetchConfig } = useWorkspaceStore();
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    fetchConfig();
  }, []);

  const moduleDefinitions = [
    { key: "motels", label: "Quản lý Khu trọ & Phòng", desc: "Quản lý danh sách tòa nhà, danh sách phòng và trạng thái phòng", icon: Building2 },
    { key: "services", label: "Quản lý Dịch vụ", desc: "Cấu hình điện, nước, internet, rác và các phí dịch vụ kèm theo", icon: SettingsIcon },
    { key: "residents", label: "Quản lý Khách thuê", desc: "Lưu trữ thông tin khách thuê, giấy tờ căn cước", icon: Users },
    { key: "contracts", label: "Hợp đồng & Tiền cọc", desc: "Tạo và quản lý thời hạn hợp đồng, tiền cọc phòng", icon: FileText },
    { key: "meter", label: "Ghi chỉ số Điện/Nước", desc: "Nhập chỉ số công tơ điện nước hàng tháng", icon: Gauge },
    { key: "invoices", label: "Quản lý Hóa đơn", desc: "Tạo hóa đơn tự động và theo dõi thanh toán", icon: Receipt },
    { key: "reports", label: "Thống kê & Báo cáo", desc: "Báo cáo doanh thu, công nợ và tỷ lệ lấp đầy", icon: BarChart3 },
    { key: "auditLog", label: "Nhật ký hoạt động", desc: "Lưu lịch sử tác động và thay đổi trên hệ thống", icon: Layers },
  ];

  const handleToggle = async (key: string, currentValue: boolean) => {
    setSaving(true);
    setError("");
    try {
      await updateModules({ [key]: !currentValue });
      setSuccess(true);
      setTimeout(() => setSuccess(false), 2000);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 max-w-2xl">
      <div>
        <h2 className="text-base font-bold text-brand-ink border-b border-slate-100 pb-3">
          Tùy chỉnh Không gian làm việc (UC17)
        </h2>
        <p className="text-xs text-slate-500 mt-2">
          Bật hoặc tắt các module chức năng để tinh gọn giao diện thanh Menu (Sidebar) cho phù hợp với quy mô quản lý của bạn.
        </p>
      </div>

      {success && (
        <div className="flex items-center gap-3 rounded-xl bg-emerald-50 border border-emerald-100 p-4 text-emerald-700">
          <CheckCircle2 size={18} />
          <span className="text-sm font-medium">Đã cập nhật cấu hình workspace thành công!</span>
        </div>
      )}

      {error && (
        <div className="flex items-center gap-3 rounded-xl bg-red-50 border border-red-100 p-4 text-red-700">
          <AlertCircle size={18} />
          <span className="text-sm">{error}</span>
        </div>
      )}

      <div className="divide-y divide-slate-100 border border-slate-200 rounded-2xl overflow-hidden bg-slate-50/50">
        {moduleDefinitions.map((mod) => {
          const isEnabled = modules[mod.key] ?? true;
          return (
            <div key={mod.key} className="p-4 flex items-center justify-between hover:bg-white transition-colors">
              <div className="flex items-start gap-3.5">
                <div className={`p-2.5 rounded-xl ${isEnabled ? "bg-brand-deep/10 text-brand-deep" : "bg-slate-200 text-slate-500"}`}>
                  <mod.icon size={20} />
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-slate-800">{mod.label}</h4>
                  <p className="text-xs text-slate-500">{mod.desc}</p>
                </div>
              </div>
              <button
                type="button"
                disabled={saving}
                onClick={() => handleToggle(mod.key, isEnabled)}
                className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${isEnabled ? "bg-brand-deep" : "bg-slate-300"
                  }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${isEnabled ? "translate-x-5" : "translate-x-0"
                    }`}
                />
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ============ MAIN SETTINGS PAGE ============
export function SettingsPage() {
  const { user, setUser } = useAuthStore();
  const isManager = user?.role === "MANAGER";

  const TABS = [
    { id: "profile", label: "Hồ sơ cá nhân", icon: User },
    { id: "security", label: "Bảo mật & Mật khẩu", icon: Shield },
    ...(isManager ? [{ id: "workspace", label: "Tùy chỉnh Workspace", icon: Sliders }] : [])
  ];

  const [activeTab, setActiveTab] = useState<string>("profile");
  const [isSaving, setIsSaving] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  const [name, setName] = useState(user?.name || "");
  const [phone, setPhone] = useState(user?.phone || "");
  const [email, setEmail] = useState(user?.email || "");

  // Load latest profile from API on mount
  useEffect(() => {
    userService.getProfile()
      .then((profile) => {
        setName(profile.fullName);
        setEmail(profile.email);
        setPhone(profile.phone || "");
        if (user) {
          setUser({
            ...user,
            name: profile.fullName,
            email: profile.email,
            phone: profile.phone
          });
        }
      })
      .catch(() => { });
  }, []);

  const handleSaveProfile = async () => {
    setIsSaving(true);
    setError("");
    setSuccess(false);
    try {
      const updated = await userService.updateProfile({ fullName: name, phone, email });
      if (user) {
        setUser({
          ...user,
          name: updated.fullName,
          phone: updated.phone,
          email: updated.email
        });
      }
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsSaving(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Cài đặt hệ thống</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý thông tin cá nhân, mật khẩu bảo mật và không gian làm việc</p>
        </div>
        {activeTab === "profile" && (
          <Button onClick={handleSaveProfile} disabled={isSaving}>
            <Save size={16} className="mr-2" />
            {isSaving ? "Đang lưu..." : "Lưu hồ sơ"}
          </Button>
        )}
      </div>

      {success && (
        <div className="flex items-center gap-3 rounded-xl bg-emerald-50 border border-emerald-100 p-4 text-emerald-700 max-w-lg">
          <CheckCircle2 size={18} />
          <span className="text-sm font-medium">Thay đổi thông tin hồ sơ đã được cập nhật thành công!</span>
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
        <div className="w-full lg:w-64 space-y-1">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              id={`settings-tab-${tab.id}`}
              onClick={() => setActiveTab(tab.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-xl transition-all ${activeTab === tab.id
                ? "bg-white text-brand-deep shadow-sm border border-slate-200 font-semibold"
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
              <h2 className="text-base font-bold text-brand-ink border-b border-slate-100 pb-3">Hồ sơ cá nhân</h2>
              {/* Avatar */}
              <div className="flex items-center gap-4">
                <div className="w-16 h-16 rounded-2xl bg-brand-deep flex items-center justify-center text-white font-bold text-2xl">
                  {name?.charAt(0).toUpperCase() ?? "U"}
                </div>
                <div>
                  <p className="font-semibold text-brand-ink">{name}</p>
                  <p className="text-xs text-slate-500 uppercase font-medium">{user?.role}</p>
                </div>
              </div>

              <div className="space-y-4">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700">Họ và tên *</label>
                  <input
                    id="profile-name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className={inputClass}
                    required
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
                      placeholder="0912345678"
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
                      placeholder="user@example.com"
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
            </div>
          )}

          {/* Workspace Tab (UC17) */}
          {activeTab === "workspace" && (
            <WorkspaceConfigSection />
          )}
        </div>
      </div>
    </div>
  );
}

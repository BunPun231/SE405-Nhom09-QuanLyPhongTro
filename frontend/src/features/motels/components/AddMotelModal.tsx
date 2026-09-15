import { useState, useEffect } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { motelService, type MotelResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { useTourGuide } from "@/hooks/useTourGuide";
import {
  Copy, Check, ChevronLeft, ChevronRight, HelpCircle, ShieldCheck, ChevronUp, ChevronDown, Maximize2, X
} from "lucide-react";

import accessWebhookImg from "../../../../image/AccessWebhook.png";
import step1AddWebhookImg from "../../../../image/Step1-AddWebhook.png";
import step2AddWebhookImg from "../../../../image/Step2-AddWebhook.png";
import step3AddWebhookImg from "../../../../image/Step3-AddWebhook.png";
import step4AddWebhookImg from "../../../../image/Step4-AddWebhook.png";

interface AddMotelModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  motel?: MotelResult;
}

const GUIDE_STEPS = [
  {
    title: "Vào quản lý Webhook",
    desc: "Đăng nhập vào SePay.vn, vào mục 'Tích hợp' -> chọn 'Webhooks' ở menu bên trái. Bấm vào nút 'Thêm Webhook' ở góc phải màn hình để mở hộp thoại thêm mới",
    img: accessWebhookImg
  },
  {
    title: "Nhập đường dẫn Webhook",
    desc: "Dán đường dẫn Webhook URL đã sao chép từ phần mềm của bác vào ô 'URL nhận webhook' và chọn các sự kiện giao dịch.",
    img: step1AddWebhookImg
  },
  {
    title: "Chọn tài khoản ngân hàng nhận tiền",
    desc: "Chọn tài khoản ngân hàng bác muốn nhận tiền. Tài khoản này sẽ được dùng để nhận tiền từ các giao dịch được thực hiện qua SePay.vn. Hoặc có thể để mặc định là Tất cả tài khoản. Sau đó thì bấm Tiếp theo",
    img: step2AddWebhookImg
  },
  {
    title: "Điền Secret Key bảo mật",
    desc: "Sao chép Secret Key ở trên dán vào ô 'Chữ ký bảo mật (Signature Secret Key)' để đảm bảo truyền tin an toàn theo chuẩn HMAC-SHA256.",
    img: step3AddWebhookImg
  },
  {
    title: "Lưu & Kích hoạt Webhook",
    desc: "Bấm 'Thêm' trên SePay.vn. Trạng thái Webhook hiển thị hoạt động là đã thành công kết nối bảo mật!",
    img: step4AddWebhookImg
  }
];

export function AddMotelModal({ isOpen, onClose, onSuccess, motel }: AddMotelModalProps) {
  const { activeSubStepId, setActiveSubStepId } = useTourGuide();
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");
  const [totalFloors, setTotalFloors] = useState("1");
  const [description, setDescription] = useState("");
  const [closingDay, setClosingDay] = useState("5");
  const [depositRate, setDepositRate] = useState("100");
  const [bankId, setBankId] = useState("");
  const [bankAccount, setBankAccount] = useState("");
  const [accountHolder, setAccountHolder] = useState("");
  const [bankName, setBankName] = useState("");
  const [secretKey, setSecretKey] = useState("");

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  // Webhook Guide states
  const [copied, setCopied] = useState<"url" | "key" | null>(null);
  const [showGuide, setShowGuide] = useState(false);
  const [guideStep, setGuideStep] = useState(1);
  const [isFullscreenOpen, setIsFullscreenOpen] = useState(false);

  useEffect(() => {
    if (isOpen) {
      if (motel) {
        setName(motel.name);
        setAddress(motel.address);
        setTotalFloors(motel.totalFloors.toString());
        setDescription(motel.description ?? "");
        setClosingDay(motel.billingCycleDay !== undefined && motel.billingCycleDay !== null ? motel.billingCycleDay.toString() : "last");
        setDepositRate(motel.depositPercent !== undefined && motel.depositPercent !== null ? motel.depositPercent.toString() : "100");
        if (motel.bankConfig) {
          try {
            const cfg = JSON.parse(motel.bankConfig);
            setBankId(cfg.bankId || "");
            setBankAccount(cfg.bankAccount || "");
            setAccountHolder(cfg.accountHolder || "");
            setBankName(cfg.bankName || "");
            if (cfg.secretKey) {
              setSecretKey(cfg.secretKey);
            } else {
              motelService.generateSecret()
                .then(key => setSecretKey(key))
                .catch(err => console.error("Failed to generate secret key", err));
            }
          } catch (e) {
            console.error("Failed to parse bank config, fetching new key", e);
            motelService.generateSecret()
              .then(key => setSecretKey(key))
              .catch(err => console.error("Failed to generate secret key", err));
          }
        } else {
          setBankId("");
          setBankAccount("");
          setAccountHolder("");
          setBankName("");
          motelService.generateSecret()
            .then(key => setSecretKey(key))
            .catch(err => console.error("Failed to generate secret key", err));
        }
      } else {
        setName("");
        setAddress("");
        setTotalFloors("1");
        setDescription("");
        setClosingDay("5");
        setDepositRate("100");
        setBankId("");
        setBankAccount("");
        setAccountHolder("");
        setBankName("");
        // Pre-fetch securely generated secretKey from backend
        motelService.generateSecret()
          .then(key => setSecretKey(key))
          .catch(err => console.error("Failed to pre-fetch secret key", err));
      }
      setError("");
      setCopied(null);
      setShowGuide(false);
      setGuideStep(1);
      setIsFullscreenOpen(false);
    }
  }, [motel, isOpen]);

  // Sync guideStep with activeSubStepId from tour guide
  useEffect(() => {
    if (activeSubStepId && activeSubStepId.startsWith("1.")) {
      const stepMap: Record<string, number> = {
        "1.11": 1,
        "1.12": 1,
        "1.13": 2,
        "1.14": 3,
        "1.15": 3,
        "1.16": 4,
        "1.17": 5,
        "1.18": 5
      };
      const targetGuideStep = stepMap[activeSubStepId];
      if (targetGuideStep !== undefined) {
        if (guideStep !== targetGuideStep) {
          setGuideStep(targetGuideStep);
        }
        // Auto-expand showGuide only for the steps where modal should be open
        const shouldBeOpen = ["1.11", "1.13", "1.14", "1.16", "1.17"].includes(activeSubStepId);
        if (shouldBeOpen && !showGuide) {
          setShowGuide(true);
        }
      }
    }
  }, [activeSubStepId, guideStep, showGuide]);

  // Fullscreen Keyboard listeners
  useEffect(() => {
    if (!isFullscreenOpen) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "ArrowLeft" && guideStep > 1) {
        setGuideStep(prev => prev - 1);
      } else if (e.key === "ArrowRight" && guideStep < 5) {
        setGuideStep(prev => prev + 1);
      } else if (e.key === "Escape") {
        setIsFullscreenOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isFullscreenOpen, guideStep]);

  const handleCopy = (text: string, type: "url" | "key") => {
    navigator.clipboard.writeText(text);
    setCopied(type);
    setTimeout(() => setCopied(null), 2000);

    // Auto-advance guide step on copy
    if (activeSubStepId === "1.12" && type === "url") {
      setActiveSubStepId("1.13");
      localStorage.setItem("onboarding_substep", "1.13");
    } else if (activeSubStepId === "1.15" && type === "key") {
      setActiveSubStepId("1.16");
      localStorage.setItem("onboarding_substep", "1.16");
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);
    try {
      const bankConfigObj: any = {
        secretKey
      };
      if (bankId && bankAccount && accountHolder) {
        bankConfigObj.bankId = bankId;
        bankConfigObj.bankAccount = bankAccount.trim();
        bankConfigObj.accountHolder = accountHolder.trim();
        bankConfigObj.bankName = bankName;
      }

      const payload = {
        name: name.trim(),
        address: address.trim(),
        totalFloors: parseInt(totalFloors, 10),
        description: description.trim() || undefined,
        billingCycleDay: closingDay === "last" ? undefined : parseInt(closingDay, 10),
        depositPercent: parseFloat(depositRate) || 0,
        bankConfig: JSON.stringify(bankConfigObj),
      };

      let savedMotel;
      if (motel) {
        savedMotel = await motelService.update(motel.id, payload);
      } else {
        savedMotel = await motelService.create(payload);
      }

      localStorage.setItem(`motel_settings_${savedMotel.id}`, JSON.stringify({
        paymentCycle: 1,
        closingDay: closingDay === "last" ? 30 : parseInt(closingDay, 10),
        depositRate: parseFloat(depositRate),
      }));

      onSuccess?.();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all bg-white";
  const webhookUrl = import.meta.env.VITE_SEPAY_WEBHOOK_URL || `${window.location.origin}/api/v1/payments/webhook`;

  return (
    <>
      <Modal isOpen={isOpen} onClose={onClose} title={motel ? "Cập nhật khu trọ" : "Thêm khu trọ mới"}>
        <form onSubmit={handleSubmit} className="space-y-4 max-h-[85vh] overflow-y-auto pr-1">
          {error && (
            <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
              {error}
            </div>
          )}

          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Tên khu trọ *</label>
            <input
              id="input-motel-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  if (activeSubStepId === "1.2") {
                    setActiveSubStepId("1.3");
                    localStorage.setItem("onboarding_substep", "1.3");
                  }
                }
              }}
              placeholder="VD: Khu trọ Hoàng Hoa Thám"
              required
              className={inputClass}
            />
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Địa chỉ *</label>
            <input
              id="input-motel-address"
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  if (activeSubStepId === "1.3") {
                    setActiveSubStepId("1.4");
                    localStorage.setItem("onboarding_substep", "1.4");
                  }
                }
              }}
              placeholder="Số nhà, tên đường, phường, quận, thành phố"
              required
              className={inputClass}
            />
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Số tầng *</label>
            <input
              id="input-motel-floors"
              type="number"
              value={totalFloors}
              onChange={(e) => setTotalFloors(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  if (activeSubStepId === "1.4") {
                    setActiveSubStepId("1.5");
                    localStorage.setItem("onboarding_substep", "1.5");
                  }
                }
              }}
              min={1}
              max={50}
              required
              className={inputClass}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Ngày chốt kỳ *</label>
              <select
                id="select-closing-day"
                value={closingDay}
                onChange={(e) => {
                  setClosingDay(e.target.value);
                  if (activeSubStepId === "1.5") {
                    setActiveSubStepId("1.6");
                    localStorage.setItem("onboarding_substep", "1.6");
                  }
                }}
                className={inputClass}
                required
              >
                {Array.from({ length: 28 }, (_, i) => i + 1).map((d) => (
                  <option key={d} value={d.toString()}>Ngày {d} hàng tháng</option>
                ))}
                <option value="last">Ngày cuối tháng</option>
              </select>
            </div>
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Tỷ lệ tiền cọc (%) *</label>
              <input
                id="input-deposit-ratio"
                type="number"
                value={depositRate}
                onChange={(e) => setDepositRate(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    if (activeSubStepId === "1.6") {
                      setActiveSubStepId("1.7");
                      localStorage.setItem("onboarding_substep", "1.7");
                    }
                  }
                }}
                min={0}
                required
                className={inputClass}
              />
            </div>
          </div>

          {/* Webhook guide synchronization handles step adjustments automatically */}

          {/* Bank Config options - Visible in both flows */}
          <div className="rounded-2xl border border-slate-200 p-4 bg-slate-50/50 space-y-3">
            <h4 className="font-semibold text-sm text-slate-800 font-sans">Cấu hình tài khoản nhận tiền (VietQR)</h4>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Ngân hàng</label>
                <select
                  id="select-bank-name"
                  value={bankId}
                  onChange={(e) => {
                    setBankId(e.target.value);
                    const bankNames: Record<string, string> = {
                      MB: "MBBank",
                      VCB: "Vietcombank",
                      ICB: "VietinBank",
                      ACB: "ACB",
                      BIDV: "BIDV",
                      TCB: "Techcombank",
                      VIB: "VIB",
                    };
                    setBankName(bankNames[e.target.value] || e.target.value);
                    if (activeSubStepId === "1.7") {
                      setActiveSubStepId("1.8");
                      localStorage.setItem("onboarding_substep", "1.8");
                    }
                  }}
                  className={inputClass}
                >
                  <option value="">Chọn ngân hàng</option>
                  <option value="MB">MB Bank (Quân Đội)</option>
                  <option value="VCB">Vietcombank</option>
                  <option value="ICB">VietinBank</option>
                  <option value="ACB">ACB</option>
                  <option value="BIDV">BIDV</option>
                  <option value="TCB">Techcombank</option>
                  <option value="VIB">VIB</option>
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-xs font-medium text-slate-600">Số tài khoản</label>
                <input
                  id="input-bank-account"
                  type="text"
                  value={bankAccount}
                  onChange={(e) => setBankAccount(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      if (activeSubStepId === "1.8") {
                        setActiveSubStepId("1.9");
                        localStorage.setItem("onboarding_substep", "1.9");
                      }
                    }
                  }}
                  placeholder="VD: 190304567899"
                  className={inputClass}
                />
              </div>
            </div>
            <div className="space-y-1 font-sans">
              <label className="text-xs font-medium text-slate-600">Tên chủ tài khoản (Không dấu)</label>
              <input
                id="input-account-holder"
                type="text"
                value={accountHolder}
                onChange={(e) => setAccountHolder(e.target.value.toUpperCase())}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    if (activeSubStepId === "1.9") {
                      setActiveSubStepId("1.10");
                      localStorage.setItem("onboarding_substep", "1.10");
                    }
                  }
                }}
                placeholder="VD: NGUYEN TRAN PHUONG"
                className={inputClass}
              />
            </div>
            <div className="pt-2 flex justify-end">
              <Button
                id="btn-save-payment-config"
                type="button"
                variant="outline"
                size="sm"
                onClick={() => {
                  if (activeSubStepId === "1.9") {
                    setActiveSubStepId("1.10");
                    localStorage.setItem("onboarding_substep", "1.10");
                  }
                }}
                className="text-xs font-bold bg-white"
              >
                Tiếp tục cấu hình SePay
              </Button>
            </div>
          </div>

          {/* Webhook & Secret Key Configuration - Visible in both creation & update flows */}
          <div className="rounded-2xl border border-blue-150 p-4 bg-blue-50/20 space-y-4 font-sans">
            <div className="flex items-center gap-2 text-blue-700">
              <ShieldCheck size={18} />
              <h4 className="font-bold text-sm">Tích hợp Webhook SePay.vn (HMAC-SHA256)</h4>
            </div>

            <div className="space-y-3 text-left">
              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500">Đường dẫn Webhook (Webhook URL)</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    readOnly
                    value={webhookUrl}
                    className="w-full px-3 py-2 bg-slate-100 border border-slate-200 rounded-lg text-xs font-mono select-all focus:outline-none"
                  />
                  <Button
                    id="btn-copy-webhook-url"
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => handleCopy(webhookUrl, "url")}
                    className="text-xs shrink-0 flex items-center gap-1 font-bold bg-white"
                  >
                    {copied === "url" ? <Check size={14} className="text-green-600" /> : <Copy size={14} />}
                    {copied === "url" ? "Đã chép" : "Sao chép"}
                  </Button>
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-semibold text-slate-500">Mã ký xác thực (Secret Key)</label>
                <div className="flex gap-2">
                  <input
                    id="btn-copy-secret-key-input"
                    type="text"
                    readOnly
                    value={secretKey}
                    className="w-full px-3 py-2 bg-slate-100 border border-slate-200 rounded-lg text-xs font-mono select-all focus:outline-none"
                  />
                  <Button
                    id="btn-copy-secret-key"
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => handleCopy(secretKey, "key")}
                    className="text-xs shrink-0 flex items-center gap-1 font-bold bg-white"
                  >
                    {copied === "key" ? <Check size={14} className="text-green-600" /> : <Copy size={14} />}
                    {copied === "key" ? "Đã chép" : "Sao chép"}
                  </Button>
                </div>
              </div>
            </div>

            {/* Expander for step-by-step images */}
            <div className="border-t border-slate-100 pt-3">
              <button
                id="btn-trigger-sepay-guide-slider"
                type="button"
                onClick={() => setShowGuide(!showGuide)}
                className="w-full flex items-center justify-between text-xs font-extrabold text-blue-600 hover:underline cursor-pointer"
              >
                <span className="flex items-center gap-1.5">
                  <HelpCircle size={14} />
                  Xem ảnh hướng dẫn cấu hình chi tiết trên SePay.vn
                </span>
                {showGuide ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
              </button>

              {showGuide && (
                <div className="mt-3 bg-white border border-slate-150 rounded-xl p-4 space-y-3 animate-fade-in text-left">
                  <div className="flex justify-between items-center text-xs font-bold text-slate-500">
                    <span>Bước {guideStep}/5: {GUIDE_STEPS[guideStep - 1].title}</span>
                    <div className="flex gap-2">
                      <button
                        type="button"
                        disabled={guideStep === 1}
                        onClick={() => {
                          const prev = guideStep - 1;
                          setGuideStep(prev);
                          if (activeSubStepId.startsWith("1.")) {
                            const subStepMap: Record<number, string> = {
                              1: "1.11",
                              2: "1.12",
                              3: "1.13",
                              4: "1.14",
                              5: "1.15"
                            };
                            const mapped = subStepMap[prev];
                            if (mapped) {
                              setActiveSubStepId(mapped);
                              localStorage.setItem("onboarding_substep", mapped);
                            }
                          }
                        }}
                        className="p-1 hover:bg-slate-100 rounded disabled:opacity-30 cursor-pointer"
                      >
                        <ChevronLeft size={16} />
                      </button>
                      <button
                        type="button"
                        disabled={guideStep === 5}
                        onClick={() => {
                          const next = guideStep + 1;
                          setGuideStep(next);
                          if (activeSubStepId.startsWith("1.")) {
                            const subStepMap: Record<number, string> = {
                              1: "1.11",
                              2: "1.13",
                              3: "1.14",
                              4: "1.16",
                              5: "1.17"
                            };
                            const mapped = subStepMap[next];
                            if (mapped) {
                              setActiveSubStepId(mapped);
                              localStorage.setItem("onboarding_substep", mapped);
                            }
                          }
                        }}
                        className="p-1 hover:bg-slate-100 rounded disabled:opacity-30 cursor-pointer"
                      >
                        <ChevronRight size={16} />
                      </button>
                    </div>
                  </div>

                  <p className="text-[11px] text-slate-650 leading-relaxed font-sans font-normal">
                    {GUIDE_STEPS[guideStep - 1].desc}
                  </p>

                  <div id="sepay-guide-image-viewport" className="border border-slate-100 rounded-lg overflow-hidden bg-slate-50 flex flex-col items-center justify-center p-2 min-h-[180px] relative group">
                    <img
                      src={GUIDE_STEPS[guideStep - 1].img}
                      alt="Instruction guide"
                      className="max-h-[220px] object-contain rounded"
                    />
                    <button
                      type="button"
                      id="btn-open-sepay-image-modal"
                      onClick={() => setIsFullscreenOpen(true)}
                      className="absolute bottom-2 right-2 p-1.5 bg-black/60 hover:bg-black/80 text-white rounded-lg transition-colors flex items-center gap-1 text-[10px] font-bold"
                    >
                      <Maximize2 size={12} />
                      Phóng to
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Ghi chú</label>
            <textarea
              id="motel-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Thông tin thêm về khu trọ (tùy chọn)"
              rows={2}
              className={`${inputClass} resize-none`}
            />
          </div>

          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>
              Hủy
            </Button>
            <Button id="btn-submit-motel" type="submit" disabled={isLoading}>
              {isLoading ? "Đang lưu..." : (motel ? "Cập nhật" : "Thêm khu trọ")}
            </Button>
          </div>
        </form>
      </Modal>

      {/* Fullscreen guide slide zoom popup */}
      {isFullscreenOpen && (
        <div className="fixed inset-0 z-[100000] bg-black/95 flex flex-col items-center justify-between p-6 animate-fade-in font-sans">
          {/* Top header */}
          <div className="w-full max-w-5xl flex justify-between items-center text-white pb-4 border-b border-white/10">
            <div>
              <h3 className="text-lg font-bold">Hướng Dẫn Cấu Hình SePay Webhook</h3>
              <p className="text-xs text-slate-400">Bước {guideStep}/5: {GUIDE_STEPS[guideStep - 1].title}</p>
            </div>
            <button
              id="btn-close-sepay-image-modal"
              onClick={() => setIsFullscreenOpen(false)}
              className="p-2 hover:bg-white/10 rounded-full transition-colors text-white cursor-pointer"
            >
              <X size={24} />
            </button>
          </div>

          {/* Main content */}
          <div className="flex-1 w-full max-w-5xl flex items-center justify-between gap-6 my-4">
            {/* Prev button */}
            <button
              disabled={guideStep === 1}
              onClick={() => {
                const prev = guideStep - 1;
                setGuideStep(prev);
                if (activeSubStepId.startsWith("1.")) {
                  const subStepMap: Record<number, string> = {
                    1: "1.11",
                    2: "1.13",
                    3: "1.14",
                    4: "1.16",
                    5: "1.17"
                  };
                  const mapped = subStepMap[prev];
                  if (mapped) {
                    setActiveSubStepId(mapped);
                    localStorage.setItem("onboarding_substep", mapped);
                  }
                }
              }}
              className="p-3 bg-white/5 hover:bg-white/10 disabled:opacity-20 text-white rounded-full transition-all cursor-pointer disabled:cursor-not-allowed shrink-0"
            >
              <ChevronLeft size={36} />
            </button>

            {/* Image zoom wrapper */}
            <div className="flex-1 h-full flex flex-col items-center justify-center space-y-4">
              <img
                id="sepay-guide-step-image"
                src={GUIDE_STEPS[guideStep - 1].img}
                alt="Fullscreen guide detail"
                className="max-h-[60vh] max-w-full object-contain rounded-xl border border-white/10 shadow-2xl bg-slate-900/50 p-2"
              />
              <p className="text-slate-300 text-sm max-w-2xl text-center leading-relaxed">
                {GUIDE_STEPS[guideStep - 1].desc}
              </p>
            </div>

            {/* Next button */}
            <button
              disabled={guideStep === 5}
              onClick={() => {
                const next = guideStep + 1;
                setGuideStep(next);
                if (activeSubStepId.startsWith("1.")) {
                  const subStepMap: Record<number, string> = {
                    1: "1.11",
                    2: "1.13",
                    3: "1.14",
                    4: "1.16",
                    5: "1.17"
                  };
                  const mapped = subStepMap[next];
                  if (mapped) {
                    setActiveSubStepId(mapped);
                    localStorage.setItem("onboarding_substep", mapped);
                  }
                }
              }}
              className="p-3 bg-white/5 hover:bg-white/10 disabled:opacity-20 text-white rounded-full transition-all cursor-pointer disabled:cursor-not-allowed shrink-0"
            >
              <ChevronRight size={36} />
            </button>
          </div>

          {/* Bottom dots */}
          <div className="flex gap-2.5 pb-4">
            {GUIDE_STEPS.map((_, idx) => (
              <button
                key={idx}
                onClick={() => {
                  const targetStep = idx + 1;
                  setGuideStep(targetStep);
                  if (activeSubStepId.startsWith("1.")) {
                    const subStepMap: Record<number, string> = {
                      1: "1.11",
                      2: "1.13",
                      3: "1.14",
                      4: "1.16",
                      5: "1.17"
                    };
                    const mapped = subStepMap[targetStep];
                    if (mapped) {
                      setActiveSubStepId(mapped);
                      localStorage.setItem("onboarding_substep", mapped);
                    }
                  }
                }}
                className={`w-3 h-3 rounded-full transition-all cursor-pointer ${guideStep === idx + 1 ? "bg-blue-500 scale-125" : "bg-white/30 hover:bg-white/50"
                  }`}
              />
            ))}
          </div>
        </div>
      )}
    </>
  );
}

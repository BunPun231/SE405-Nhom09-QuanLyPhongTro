import { useState, useEffect, useRef } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { api } from "@/lib/api";
import { formatCurrency } from "@/lib/utils";
import { extractError } from "@/lib/api";
import { useNotificationStore } from "@/store/notificationStore";
import { Copy, Check, Loader2, CheckCircle2, AlertCircle } from "lucide-react";
import { useTourGuide } from "@/hooks/useTourGuide";
import { useAuthStore } from "@/store/authStore";

interface VietQrPaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  invoiceId: number;
  onSuccess: () => void;
}

interface PaymentInfo {
  bankId: string;
  bankAccount: string;
  accountHolder: string;
  bankName: string;
  amount: number;
  memo: string;
  qrUrl: string;
}

export function VietQrPaymentModal({ isOpen, onClose, invoiceId, onSuccess }: VietQrPaymentModalProps) {
  const { user } = useAuthStore();
  const { completeTenantOnboarding } = useTourGuide();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [paymentInfo, setPaymentInfo] = useState<PaymentInfo | null>(null);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [isPaid, setIsPaid] = useState(false);

  const notifications = useNotificationStore((state) => state.notifications);
  const processedNotifIds = useRef<Set<number>>(new Set());

  // Reset processed IDs on open/change
  useEffect(() => {
    if (isOpen) {
      processedNotifIds.current = new Set();
    }
  }, [isOpen, invoiceId]);

  // Complete tenant onboarding on mount/unmount if user is tenant
  useEffect(() => {
    if (isOpen) {
      const isTenant = !!(user && ((user.role as string) === "TENANT" || (user.role as string) === "RESIDENT"));
      if (isTenant) {
        completeTenantOnboarding();
      }
    }
    return () => {
      const isTenant = !!(user && ((user.role as string) === "TENANT" || (user.role as string) === "RESIDENT"));
      if (isTenant) {
        completeTenantOnboarding();
      }
    };
  }, [isOpen, user, completeTenantOnboarding]);

  // 1. Fetch payment details
  useEffect(() => {
    if (isOpen) {
      setLoading(true);
      setError("");
      setIsPaid(false);
      api.get<PaymentInfo>(`/api/v1/invoices/${invoiceId}/payment-info`)
        .then((res) => {
          setPaymentInfo(res.data);
        })
        .catch((err) => {
          setError(extractError(err));
        })
        .finally(() => {
          setLoading(false);
        });
    }
  }, [isOpen, invoiceId]);

  // 2. WebSocket real-time check
  useEffect(() => {
    if (!isOpen || isPaid) return;

    // Find a payment notification matching this invoice that has not been processed yet
    const newPaymentNotif = notifications.find(
      (n) => n.type === "PAYMENT" && 
             n.actionUrl?.endsWith(`/${invoiceId}`) && 
             !processedNotifIds.current.has(n.id)
    );

    if (newPaymentNotif) {
      // Mark it as processed immediately to prevent double processing
      processedNotifIds.current.add(newPaymentNotif.id);

      // Re-fetch invoice details to determine if fully or partially paid
      api.get<any>(`/api/v1/invoices/${invoiceId}`)
        .then((res) => {
          const inv = res.data;
          const audio = new Audio("https://assets.mixkit.co/active_storage/sfx/2013/2013-84.wav");
          audio.play().catch(() => {});

          if (inv.status === "PAID") {
            setIsPaid(true);
          } else {
            // Partially paid!
            // Refresh payment info to get updated QR and remaining amount
            api.get<PaymentInfo>(`/api/v1/invoices/${invoiceId}/payment-info`)
              .then((piRes) => {
                setPaymentInfo(piRes.data);
                alert(`Bạn đã thanh toán một phần thành công! Số tiền còn lại cần thanh toán: ${formatCurrency(piRes.data.amount)}`);
                // Trigger onSuccess to update parent invoice lists in the background
                onSuccess();
              })
              .catch((err) => {
                console.error("Failed to refresh payment info after partial payment", err);
              });
          }
        })
        .catch((err) => {
          console.error("Failed to load invoice status after payment notification", err);
        });
    }
  }, [notifications, invoiceId, isOpen, isPaid, onSuccess]);

  const copyToClipboard = (text: string, field: string) => {
    navigator.clipboard.writeText(text);
    setCopiedField(field);
    setTimeout(() => {
      setCopiedField(null);
    }, 2000);
  };

  const handleFinish = () => {
    onSuccess();
    onClose();
    if ((user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT") {
      completeTenantOnboarding();
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Thanh toán hóa đơn #${invoiceId}`}>
      {loading ? (
        <div className="flex flex-col items-center justify-center py-12 space-y-3">
          <Loader2 className="animate-spin text-brand-deep" size={36} />
          <p className="text-sm text-slate-500 font-medium">Đang tải mã thanh toán QR...</p>
        </div>
      ) : error ? (
        <div className="p-6 text-center space-y-4">
          <div className="mx-auto w-12 h-12 rounded-full bg-red-50 flex items-center justify-center text-red-500">
            <AlertCircle size={24} />
          </div>
          <div>
            <h4 className="font-bold text-slate-800">Không thể tải thông tin thanh toán</h4>
            <p className="text-sm text-slate-500 mt-1">{error}</p>
          </div>
          <Button variant="outline" onClick={onClose} className="w-full">Đóng</Button>
        </div>
      ) : isPaid ? (
        <div className="p-6 text-center space-y-5 animate-in fade-in zoom-in-95 duration-300">
          <div className="mx-auto w-20 h-20 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-500 border-4 border-emerald-100">
            <CheckCircle2 size={48} className="animate-bounce" />
          </div>
          <div className="space-y-2">
            <h3 className="text-xl font-extrabold text-slate-800 font-display">Thanh Toán Thành Công!</h3>
            <p className="text-sm text-slate-500 px-4 leading-relaxed">
              Hệ thống đã nhận được tiền chuyển khoản của bạn. Hóa đơn #{invoiceId} đã chuyển sang trạng thái <strong>Đã thanh toán</strong>.
            </p>
          </div>
          <div className="bg-slate-50 rounded-2xl p-4 text-left border border-slate-100 text-sm space-y-2.5">
            <div className="flex justify-between">
              <span className="text-slate-400">Số tiền:</span>
              <span className="font-bold text-slate-800">{formatCurrency(paymentInfo?.amount || 0)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Hình thức:</span>
              <span className="font-medium text-slate-800">VietQR Auto Reconcile</span>
            </div>
          </div>
          <Button onClick={handleFinish} className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 rounded-xl shadow-lg shadow-emerald-600/10">
            Tuyệt vời!
          </Button>
        </div>
      ) : (
        <div id="vietqr-payment-modal-content" className="space-y-5">
          {/* QR Code Container */}
          <div className="flex flex-col items-center justify-center bg-slate-50 border border-slate-100 p-6 rounded-2xl">
            <div className="relative bg-white p-3 rounded-2xl shadow-sm border border-slate-200/50">
              <img
                src={paymentInfo?.qrUrl}
                alt="VietQR Payment Code"
                className="w-48 h-48 object-contain"
              />
              <div className="absolute inset-0 flex items-center justify-center bg-white/90 opacity-0 hover:opacity-100 transition-opacity rounded-2xl cursor-pointer">
                <span className="text-xs font-bold text-brand-deep text-center px-4">
                  Mở App Ngân hàng quét để thanh toán nhanh
                </span>
              </div>
            </div>
            <p className="text-[11px] text-slate-400 mt-3 text-center">
              Mã QR động chứa số tiền và nội dung chuyển khoản tự động.
            </p>
          </div>

          {/* Amount details */}
          <div className="bg-brand-deep/5 p-4 rounded-2xl border border-brand-deep/10 text-center space-y-0.5">
            <span className="text-[11px] text-slate-500 font-semibold tracking-wider uppercase">Số tiền cần thanh toán</span>
            <div className="flex items-center justify-center gap-1.5">
              <span className="text-2xl font-extrabold text-brand-deep font-display">
                {formatCurrency(paymentInfo?.amount || 0)}
              </span>
              <button
                onClick={() => copyToClipboard(String(paymentInfo?.amount || 0), "amount")}
                className="text-slate-400 hover:text-brand-deep p-1 transition-colors"
                title="Sao chép số tiền"
              >
                {copiedField === "amount" ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
              </button>
            </div>
          </div>

          {/* Account Details list */}
          <div className="rounded-2xl border border-slate-200 bg-white p-4 space-y-3 text-sm">
            <div className="flex justify-between items-center py-0.5">
              <span className="text-slate-500">Ngân hàng nhận</span>
              <span className="font-bold text-slate-800">{paymentInfo?.bankName} ({paymentInfo?.bankId})</span>
            </div>

            <div className="flex justify-between items-center border-t border-slate-100 pt-2.5">
              <span className="text-slate-500">Số tài khoản</span>
              <div className="flex items-center gap-1.5">
                <span className="font-mono font-bold text-slate-800">{paymentInfo?.bankAccount}</span>
                <button
                  onClick={() => copyToClipboard(paymentInfo?.bankAccount || "", "account")}
                  className="text-slate-400 hover:text-brand-deep p-1 transition-colors"
                >
                  {copiedField === "account" ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
                </button>
              </div>
            </div>

            <div className="flex justify-between items-center border-t border-slate-100 pt-2.5">
              <span className="text-slate-500">Tên người nhận</span>
              <span className="font-bold text-slate-800 uppercase">{paymentInfo?.accountHolder}</span>
            </div>

            <div className="flex justify-between items-center border-t border-slate-100 pt-2.5">
              <span className="text-slate-500">Nội dung chuyển khoản</span>
              <div className="flex items-center gap-1.5">
                <span className="font-mono font-bold bg-amber-50 text-amber-800 border border-amber-200/50 px-2.5 py-0.5 rounded-lg text-sm">
                  {paymentInfo?.memo}
                </span>
                <button
                  onClick={() => copyToClipboard(paymentInfo?.memo || "", "memo")}
                  className="text-slate-400 hover:text-brand-deep p-1 transition-colors"
                >
                  {copiedField === "memo" ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
                </button>
              </div>
            </div>
          </div>

          <div className="text-xs text-slate-500 leading-relaxed bg-amber-50/50 p-3 rounded-xl border border-amber-100/50 flex gap-2">
            <span className="text-amber-600 font-bold">⚠️ Quan trọng:</span>
            <span>
              Quý khách bắt buộc phải chuyển đúng số tiền và nội dung chuyển khoản <strong>{paymentInfo?.memo}</strong> ở trên để hệ thống tự động ghi nhận thanh toán trong 30 giây.
            </span>
          </div>

          {/* Action Footer */}
          <div className="pt-4 border-t border-slate-100 flex gap-2">
            <Button type="button" variant="outline" className="w-full" onClick={onClose}>
              Đóng
            </Button>
            <div className="w-full flex items-center justify-center bg-slate-50 text-slate-400 text-xs font-semibold rounded-xl border border-slate-200 border-dashed px-3">
              <Loader2 className="animate-spin text-brand-deep mr-2" size={14} />
              Chờ thanh toán...
            </div>
          </div>
        </div>
      )}
    </Modal>
  );
}

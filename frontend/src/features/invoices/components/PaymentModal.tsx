import { useState } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { paymentService } from "@/services/invoiceService";
import { formatCurrency } from "@/lib/utils";
import { extractError } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";

interface PaymentModalProps {
  isOpen: boolean;
  onClose: () => void;
  invoiceId: number;
  totalDebt: number;
  onSuccess: () => void;
}

export function PaymentModal({ isOpen, onClose, invoiceId, totalDebt, onSuccess }: PaymentModalProps) {
  const { user } = useAuthStore();
  const isTenant = user?.role === "TENANT";

  const [amount, setAmount] = useState(totalDebt.toString());
  const [method, setMethod] = useState("CASH");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await paymentService.pay({
        invoiceId,
        amount: isTenant ? totalDebt : parseFloat(amount),
        paymentMethod: isTenant ? "BANK_TRANSFER" : method,
      });
      onSuccess();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all bg-white";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={isTenant ? `Thanh toán hóa đơn #${invoiceId}` : `Thu tiền hóa đơn #${invoiceId}`}>
      {isTenant ? (
        <div className="space-y-5">
          {error && (
            <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
              {error}
            </div>
          )}

          <div className="bg-brand-deep/5 p-5 rounded-2xl border border-brand-deep/10 text-center space-y-1">
            <p className="text-xs text-slate-500 font-medium">SỐ TIỀN CẦN THANH TOÁN</p>
            <p className="text-3xl font-extrabold text-brand-deep font-display">{formatCurrency(totalDebt)}</p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-slate-50/50 p-4 space-y-3.5 text-sm">
            <h4 className="font-semibold text-slate-800 border-b border-slate-200 pb-2">Thông tin tài khoản nhận tiền</h4>
            
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Ngân hàng</span>
              <span className="font-bold text-slate-800">MB Bank (Ngân hàng Quân Đội)</span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Số tài khoản</span>
              <span className="font-mono font-bold text-brand-deep text-base">1903 0456 7899</span>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-slate-500">Chủ tài khoản</span>
              <span className="font-bold text-slate-800 uppercase">NGUYEN TRAN PHUONG (CHU TRO)</span>
            </div>

            <div className="flex justify-between items-center">
              <span className="text-slate-500">Nội dung CK bắt buộc</span>
              <span className="font-mono font-bold bg-amber-100 text-amber-800 px-2 py-0.5 rounded">SMARTBOARDING HD{invoiceId}</span>
            </div>
          </div>

          <div className="text-xs text-slate-400 leading-relaxed bg-blue-50/50 p-3 rounded-xl border border-blue-100/50">
            💡 <strong>Hướng dẫn:</strong> Quý khách vui lòng mở ứng dụng ngân hàng quét chuyển khoản hoặc chuyển khoản thủ công theo thông tin trên. Sau khi chuyển khoản thành công, nhấn nút <strong>Xác nhận đã chuyển khoản</strong> bên dưới để hoàn tất.
          </div>

          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
              Đóng
            </Button>
            <Button id="btn-submit-payment" onClick={handleSubmit} disabled={loading} className="bg-emerald-600 hover:bg-emerald-700 text-white font-semibold">
              {loading ? "Đang xử lý..." : "Tôi đã chuyển khoản"}
            </Button>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
              {error}
            </div>
          )}

          <div className="bg-brand-deep/5 p-4 rounded-xl border border-brand-deep/10 text-center">
            <p className="text-sm text-slate-500 mb-1">Số tiền cần thu</p>
            <p className="text-2xl font-bold text-brand-ink">{formatCurrency(totalDebt)}</p>
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Số tiền khách đưa *</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              min={1000}
              max={totalDebt * 2} // Allow some overpayment to save as credit? Or just limit to totalDebt.
              required
              className={inputClass}
            />
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Hình thức thanh toán</label>
            <select
              value={method}
              onChange={(e) => setMethod(e.target.value)}
              className={inputClass}
            >
              <option value="CASH">Tiền mặt</option>
              <option value="BANK_TRANSFER">Chuyển khoản</option>
              <option value="E_WALLET">Ví điện tử</option>
            </select>
          </div>

          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
              Hủy
            </Button>
            <Button id="btn-submit-payment" type="submit" disabled={loading}>
              {loading ? "Đang xử lý..." : "Xác nhận thu"}
            </Button>
          </div>
        </form>
      )}
    </Modal>
  );
}

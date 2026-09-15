import { useState } from "react";
import { Plus, Trash2, Image as ImageIcon } from "lucide-react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { contractService, type SettlementCalculateResult, type DamageItemInput } from "@/services/contractService";
import { formatCurrency, formatVnStyle, stripVnStyle } from "@/lib/utils";
import { extractError } from "@/lib/api";

interface SettlementModalProps {
  isOpen: boolean;
  onClose: () => void;
  contractId: number;
  onSuccess: () => void;
}

export function SettlementModal({ isOpen, onClose, contractId, onSuccess }: SettlementModalProps) {
  const [step, setStep] = useState<1 | 2>(1);
  const [moveOutDate, setMoveOutDate] = useState(new Date().toISOString().slice(0, 10));
  const [finalElectric, setFinalElectric] = useState("");
  const [finalWater, setFinalWater] = useState("");
  const [damages, setDamages] = useState<DamageItemInput[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [calcResult, setCalcResult] = useState<SettlementCalculateResult | null>(null);

  const handleAddDamage = () => {
    setDamages([...damages, { itemName: "", penaltyFee: 0, imageUrl: "" }]);
  };

  const handleRemoveDamage = (index: number) => {
    setDamages(damages.filter((_, i) => i !== index));
  };

  const handleDamageChange = (index: number, field: keyof DamageItemInput, value: any) => {
    setDamages(prev => prev.map((item, i) => i === index ? { ...item, [field]: value } : item));
  };

  const handleDamageImageChange = (index: number, file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      handleDamageChange(index, "imageUrl", reader.result as string);
    };
    reader.readAsDataURL(file);
  };

  const handleCalculate = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const result = await contractService.calculateSettlement({
        contractId,
        moveOutDate,
        finalElectricReading: finalElectric ? parseFloat(finalElectric) : undefined,
        finalWaterReading: finalWater ? parseFloat(finalWater) : undefined,
        damages: damages.filter(d => d.itemName.trim() !== ""),
      });
      setCalcResult(result);
      setStep(2);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async () => {
    setError("");
    setLoading(true);
    try {
      await contractService.confirmSettlement(contractId, {
        moveOutDate,
        finalElectricReading: finalElectric ? parseFloat(finalElectric) : undefined,
        finalWaterReading: finalWater ? parseFloat(finalWater) : undefined,
        damages: damages.filter(d => d.itemName.trim() !== ""),
      });
      onSuccess();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all bg-white";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Thanh lý hợp đồng #${contractId}`} size="lg">
      {error && (
        <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700 mb-4">
          {error}
        </div>
      )}

      {step === 1 ? (
        <form onSubmit={handleCalculate} className="space-y-6 max-h-[75vh] overflow-y-auto pr-1">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Ngày chuyển đi *</label>
            <input
              type="date"
              value={moveOutDate}
              onChange={(e) => setMoveOutDate(e.target.value)}
              required
              className={inputClass}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Số điện cuối</label>
              <input
                type="number"
                step="0.01"
                value={finalElectric}
                onChange={(e) => setFinalElectric(e.target.value)}
                placeholder="Để trống nếu không có"
                className={inputClass}
              />
            </div>
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Số nước cuối</label>
              <input
                type="number"
                step="0.01"
                value={finalWater}
                onChange={(e) => setFinalWater(e.target.value)}
                placeholder="Để trống nếu không có"
                className={inputClass}
              />
            </div>
          </div>

          {/* Damages Section */}
          <div className="space-y-3">
            <div className="flex items-center justify-between border-t border-slate-100 pt-4">
              <h4 className="text-sm font-semibold text-slate-800">Kê khai tài sản hư hại / đền bù</h4>
              <Button type="button" variant="outline" size="sm" onClick={handleAddDamage}>
                <Plus size={14} className="mr-1" />
                Thêm tài sản hỏng
              </Button>
            </div>

            {damages.length === 0 ? (
              <p className="text-xs text-slate-400 italic">Chưa ghi nhận tài sản hư hại nào.</p>
            ) : (
              <div className="space-y-3">
                {damages.map((damage, idx) => (
                  <div key={idx} className="p-3 bg-slate-50 border border-slate-200 rounded-xl space-y-2 relative">
                    <button
                      type="button"
                      onClick={() => handleRemoveDamage(idx)}
                      className="absolute right-2 top-2 text-slate-400 hover:text-red-500 transition-colors"
                    >
                      <Trash2 size={16} />
                    </button>
                    <div className="grid grid-cols-2 gap-3">
                      <div className="space-y-1">
                        <label className="text-xs font-medium text-slate-500">Tên tài sản/Lỗi vi phạm</label>
                        <input
                          type="text"
                          required
                          value={damage.itemName}
                          onChange={(e) => handleDamageChange(idx, "itemName", e.target.value)}
                          placeholder="VD: Hỏng khóa cửa, Mất chìa khóa"
                          className={inputClass}
                        />
                      </div>
                      <div className="space-y-1">
                        <label className="text-xs font-medium text-slate-500">Số tiền khấu trừ (đ)</label>
                        <input
                          type="text"
                          required
                          value={formatVnStyle(damage.penaltyFee)}
                          onChange={(e) => handleDamageChange(idx, "penaltyFee", parseFloat(stripVnStyle(e.target.value)) || 0)}
                          placeholder="0"
                          className={inputClass}
                        />
                      </div>
                    </div>

                    <div className="space-y-1">
                      <label className="text-xs font-medium text-slate-500 flex items-center gap-1">
                        <ImageIcon size={12} />
                        Ảnh minh chứng hư hại
                      </label>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={(e) => handleDamageImageChange(idx, e.target.files?.[0] || null)}
                        className="text-xs text-slate-500 w-full file:mr-2 file:py-1 file:px-2 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-brand-deep/10 file:text-brand-deep hover:file:bg-brand-deep/20"
                      />
                      {damage.imageUrl && (
                        <div className="relative inline-block mt-1">
                          <img src={damage.imageUrl} alt="Hư hại" className="h-16 w-auto rounded border border-slate-200 object-cover" />
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={loading}>Hủy</Button>
            <Button type="submit" disabled={loading}>
              {loading ? "Đang tính..." : "Tính toán thanh lý"}
            </Button>
          </div>
        </form>
      ) : (
        <div className="space-y-4">
          <div className="bg-brand-deep/5 p-4 rounded-xl border border-brand-deep/10 space-y-2">
            <h3 className="font-bold text-brand-ink mb-2">Kết quả tính toán</h3>

            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Tiền cọc ban đầu:</span>
              <span className="font-medium">{formatCurrency(calcResult?.deposit || 0)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Nợ hóa đơn chưa đóng:</span>
              <span className="font-medium text-rose-600">{formatCurrency(calcResult?.currentDebt || 0)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Tiền phòng theo ngày:</span>
              <span className="font-medium">{formatCurrency(calcResult?.proRatedRent || 0)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Tiền điện nước cuối kỳ:</span>
              <span className="font-medium">{formatCurrency(calcResult?.finalUtilities || 0)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Chi phí khấu trừ tài sản:</span>
              <span className="font-medium text-rose-600">{formatCurrency(calcResult?.repairFees || 0)}</span>
            </div>

            <div className="pt-2 mt-2 border-t border-brand-deep/10 flex justify-between font-bold">
              <span>Tổng thanh toán ({calcResult?.netAmount! >= 0 ? "Khách nhận lại" : "Khách đóng thêm"}):</span>
              <span className={calcResult?.netAmount! >= 0 ? "text-emerald-600" : "text-rose-600"}>
                {formatCurrency(Math.abs(calcResult?.netAmount || 0))}
              </span>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={() => setStep(1)} disabled={loading}>Quay lại</Button>
            <Button onClick={handleConfirm} disabled={loading}>
              {loading ? "Đang xử lý..." : "Xác nhận thanh lý"}
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}

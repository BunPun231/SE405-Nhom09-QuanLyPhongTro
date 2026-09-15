import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { formatCurrency } from "@/lib/utils";
import { Printer, Send, CreditCard } from "lucide-react";
import type { InvoiceResult } from "@/services/invoiceService";

interface InvoiceDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  invoice: InvoiceResult | null;
  onCollectPayment?: () => void;
  isManager?: boolean;
}

const CHARGE_TYPE_LABEL: Record<string, string> = {
  FIXED: "Cố định",
  PER_PERSON: "Theo người",
  PER_INDEX: "Theo chỉ số (Điện/Nước)",
  PER_QUANTITY: "Theo số lượng",
  METERED: "Theo chỉ số",
  TIERED: "Lũy tiến / Bậc thang",
};

const STATUS_BADGE: Record<string, React.ReactNode> = {
  PENDING: <Badge variant="warning">Chưa thanh toán</Badge>,
  PARTIAL: <Badge variant="warning">Thanh toán một phần</Badge>,
  PAID: <Badge variant="success">Đã thanh toán</Badge>,
  VOID: <Badge variant="default">Đã hủy</Badge>,
};

function calculateItemCost(item: any): number {
  const basePrice = item.basePrice || 0;
  if (item.chargeType === "FIXED") {
    return basePrice;
  }
  if (item.chargeType === "PER_PERSON") {
    const residents = item.activeResidents || 1;
    return basePrice * residents;
  }
  if (item.chargeType === "PER_QUANTITY") {
    const qty = item.quantity || 1;
    return basePrice * qty;
  }
  if (item.chargeType === "PER_INDEX" || item.chargeType === "METERED") {
    const oldReading = item.oldReading || 0;
    const newReading = item.newReading || 0;
    const consumption = Math.max(0, newReading - oldReading);
    if (item.pricingTiers && item.pricingTiers.length > 0) {
      let remaining = consumption;
      let totalCost = 0;
      for (let i = 0; i < item.pricingTiers.length; i++) {
        if (remaining <= 0) break;
        const tier = item.pricingTiers[i];
        const start = tier.tierStart || 0;
        const end = tier.tierEnd;
        const price = tier.pricePerUnit || 0;
        const capacity = end ? (end - start) : remaining;
        const inTier = Math.min(remaining, capacity);
        if (inTier > 0) {
          totalCost += inTier * price;
          remaining -= inTier;
        }
      }
      return totalCost;
    } else {
      return consumption * basePrice;
    }
  }
  return 0;
}

export function InvoiceDetailModal({ isOpen, onClose, invoice, onCollectPayment, isManager = true }: InvoiceDetailModalProps) {
  if (!invoice) return null;

  let snapshot: any = null;
  if (invoice.calculationSnapshot) {
    try {
      snapshot = typeof invoice.calculationSnapshot === "string" 
        ? JSON.parse(invoice.calculationSnapshot) 
        : invoice.calculationSnapshot;
    } catch (e) {
      console.error("Failed to parse calculationSnapshot", e);
    }
  }
  const feeItems = (invoice.details && invoice.details.length > 0)
    ? invoice.details.map((detail) => {
        const serviceName = detail.serviceName || (detail as any).description || "";
        const totalCost = detail.totalCost !== undefined ? detail.totalCost : (detail as any).lineTotal;
        const consumption = detail.consumption !== undefined ? detail.consumption : (detail as any).quantity;
        const isMeter = serviceName.toLowerCase().includes("điện") || serviceName.toLowerCase().includes("nước");
        const chargeType = detail.chargeType || (isMeter ? "PER_INDEX" : "FIXED");
        return {
          serviceName,
          chargeType,
          oldReading: detail.oldReading,
          newReading: detail.newReading,
          consumption,
          unitPrice: detail.unitPrice,
          totalCost,
        };
      })
    : (snapshot?.items || []).map((item: any) => ({
        serviceName: item.serviceName,
        chargeType: item.chargeType,
        oldReading: item.oldReading,
        newReading: item.newReading,
        consumption: item.chargeType === "PER_INDEX" || item.chargeType === "METERED"
          ? Math.max(0, (item.newReading ?? 0) - (item.oldReading ?? 0))
          : item.chargeType === "PER_PERSON"
            ? item.activeResidents
            : item.quantity,
        unitPrice: item.basePrice,
        totalCost: calculateItemCost(item),
      }));

  const handlePrint = () => {
    const printWindow = window.open("", "_blank");
    if (!printWindow) return;

    const itemsList = feeItems;

    const detailsRows = itemsList.map((detail: any, idx: number) => `
      <tr>
        <td>${idx + 1}</td>
        <td>
          <strong>${detail.serviceName}</strong><br/>
          <small>${CHARGE_TYPE_LABEL[detail.chargeType] ?? detail.chargeType}</small>
        </td>
        <td>
          ${detail.oldReading !== undefined && detail.newReading !== undefined 
            ? `${detail.oldReading} -> ${detail.newReading} (${detail.consumption})` 
            : detail.consumption ? `${detail.consumption}` : "-"}
        </td>
        <td>${formatCurrency(detail.unitPrice)}</td>
        <td style="text-align: right; font-weight: bold;">${formatCurrency(detail.totalCost)}</td>
      </tr>
    `).join("");

    printWindow.document.write(`
      <html>
        <head>
          <title>Chi Tiết Hóa Đơn #${invoice.id}</title>
          <style>
            body { font-family: "Arial", sans-serif; padding: 20px; line-height: 1.6; }
            .header { border-bottom: 2px solid #ddd; padding-bottom: 10px; margin-bottom: 20px; }
            .title { font-size: 20px; font-weight: bold; }
            table { width: 100%; border-collapse: collapse; margin-top: 15px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { bg-color: #f5f5f5; }
            .total { font-size: 16px; font-weight: bold; text-align: right; margin-top: 15px; }
          </style>
        </head>
        <body>
          <div class="header">
            <div class="title">HÓA ĐƠN TIỀN PHÒNG & DỊCH VỤ</div>
            <p>Mã hóa đơn: #${invoice.id} | Kỳ: ${invoice.billingMonth}</p>
          </div>
          <p>Phòng: P.${invoice.roomNumber || invoice.roomId}</p>
          <table>
            <thead>
              <tr>
                <th>STT</th>
                <th>Khoản chi phí</th>
                <th>Chỉ số sử dụng</th>
                <th>Đơn giá</th>
                <th style="text-align: right;">Thành tiền</th>
              </tr>
            </thead>
            <tbody>
              ${detailsRows}
            </tbody>
          </table>
          <div class="total">
            Tổng cộng: ${formatCurrency(invoice.totalAmount)}
          </div>
        </body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    setTimeout(() => {
      printWindow.print();
      printWindow.close();
    }, 500);
  };

  const handleShare = () => {
    alert(`Chia sẻ thông tin hóa đơn #${invoice.id} qua Zalo/Email cho khách thuê.`);
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Chi tiết hóa đơn #${invoice.id}`} size="lg">
      <div className="space-y-6 max-h-[75vh] overflow-y-auto pr-2">
        
        {/* Header summary */}
        <div className="flex justify-between items-start border-b border-slate-100 pb-4">
          <div>
            <h2 className="text-xl font-bold text-brand-ink">Phòng P.{invoice.roomNumber || invoice.roomId}</h2>
            <p className="text-sm text-slate-500 mt-1">
              Kỳ hóa đơn: {invoice.billingMonth ? new Date(invoice.billingMonth).toLocaleDateString("vi-VN", { month: "long", year: "numeric" }) : "-"}
            </p>
          </div>
          <div className="text-right">
            {STATUS_BADGE[invoice.status]}
            {invoice.dueDate && (
              <p className="text-xs text-slate-400 mt-2">
                Hạn thanh toán: {new Date(invoice.dueDate).toLocaleDateString("vi-VN")}
              </p>
            )}
          </div>
        </div>

        {/* Invoice breakdown list */}
        <div className="bg-slate-50 p-5 rounded-2xl border border-slate-200 space-y-4 text-sm">
          <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Chi tiết các khoản phí</h4>
          
          <div className="divide-y divide-slate-200">
            {invoice.details && invoice.details.length > 0 ? (
              invoice.details.map((detail, idx) => {
                const serviceName = detail.serviceName || (detail as any).description || "";
                const totalCost = detail.totalCost !== undefined ? detail.totalCost : (detail as any).lineTotal;
                const quantity = detail.consumption !== undefined ? detail.consumption : (detail as any).quantity;
                const isMeter = serviceName.toLowerCase().includes("điện") || serviceName.toLowerCase().includes("nước");
                const chargeType = detail.chargeType || (isMeter ? "PER_INDEX" : "FIXED");

                return (
                  <div key={idx} className="flex justify-between py-2.5 first:pt-0 last:pb-0">
                    <div className="flex flex-col">
                      <span className="font-semibold text-slate-800">{serviceName}</span>
                      <span className="text-xs text-slate-400">
                        Loại: {CHARGE_TYPE_LABEL[chargeType] ?? chargeType}
                      </span>
                      {chargeType !== "FIXED" && detail.oldReading !== undefined && detail.newReading !== undefined && (
                        <span className="text-xs text-slate-400">
                          Chỉ số: {detail.oldReading} → {detail.newReading} ({quantity} {serviceName.toLowerCase().includes("nước") ? "khối" : "số"})
                        </span>
                      )}
                      {chargeType !== "FIXED" && detail.oldReading === undefined && (
                        <span className="text-xs text-slate-400">
                          {isMeter 
                            ? `Tiêu thụ: ${quantity} ${serviceName.toLowerCase().includes("nước") ? "khối" : "số"}`
                            : `Số lượng: ${quantity}`}
                        </span>
                      )}
                      {chargeType !== "FIXED" && (
                        <span className="text-xs text-slate-400">Đơn giá: {formatCurrency(detail.unitPrice)}</span>
                      )}
                    </div>
                    <span className="font-bold text-slate-800 align-middle self-center">{formatCurrency(totalCost)}</span>
                  </div>
                );
              })
            ) : snapshot?.items && snapshot.items.length > 0 ? (
              snapshot.items.map((item: any, idx: number) => {
                const totalCost = calculateItemCost(item);
                return (
                  <div key={idx} className="flex justify-between py-2.5 first:pt-0 last:pb-0">
                    <div className="flex flex-col">
                      <span className="font-semibold text-slate-800">{item.serviceName}</span>
                      <span className="text-xs text-slate-400">
                        Loại: {CHARGE_TYPE_LABEL[item.chargeType] ?? item.chargeType}
                      </span>
                      {(item.chargeType === "PER_INDEX" || item.chargeType === "METERED") && (
                        <span className="text-xs text-slate-400">
                          Chỉ số: {item.oldReading ?? 0} → {item.newReading ?? 0} ({Math.max(0, (item.newReading ?? 0) - (item.oldReading ?? 0))} {item.serviceName.toLowerCase().includes("nước") ? "khối" : "số"})
                        </span>
                      )}
                      {item.chargeType === "PER_PERSON" && (
                        <span className="text-xs text-slate-400">
                          Đơn giá: {formatCurrency(item.basePrice)}/người ({item.activeResidents ?? 1} người)
                        </span>
                      )}
                      {item.chargeType === "PER_QUANTITY" && (
                        <span className="text-xs text-slate-400">
                          Đơn giá: {formatCurrency(item.basePrice)}/đơn vị ({item.quantity ?? 1} lượng)
                        </span>
                      )}
                    </div>
                    <span className="font-bold text-slate-800 align-middle self-center">{formatCurrency(totalCost)}</span>
                  </div>
                );
              })
            ) : (
              <div className="text-center text-slate-400 py-4">Không có chi tiết các khoản phí</div>
            )}
          </div>

          <div className="flex justify-between pt-4 border-t-2 border-brand-deep/20 font-bold">
            <span className="text-base text-brand-ink">Tổng cộng</span>
            <span className="text-xl text-rose-600">{formatCurrency(invoice.totalAmount)}</span>
          </div>
        </div>

        {/* Bảng kê chi tiết các khoản tiền đóng góp */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
          <h3 className="text-xs font-bold text-slate-500 border-b border-slate-100 pb-2 uppercase tracking-wide">
            Chi tiết các khoản tiền đóng góp
          </h3>
          <div className="divide-y divide-slate-100 text-sm">
            {feeItems.map((item: any, idx: number) => (
              <div key={idx} className="flex justify-between items-center py-2.5">
                <span className="text-slate-700 font-semibold">{item.serviceName}</span>
                <span className="text-slate-900 font-mono font-bold text-brand-ink">{formatCurrency(item.totalCost)}</span>
              </div>
            ))}
            <div className="flex justify-between items-center pt-3 font-bold text-rose-600 border-t border-slate-100">
              <span className="text-base">Tổng cộng hóa đơn</span>
              <span className="text-xl font-mono">{formatCurrency(invoice.totalAmount)}</span>
            </div>
          </div>
        </div>

        {/* Calculation formulas detailed breakdown */}
        {snapshot?.items && (
          <div className="bg-white p-5 rounded-2xl border border-slate-200 space-y-4">
            <h3 className="text-xs font-bold text-slate-500 border-b border-slate-100 pb-2 uppercase tracking-wide">
              Công thức tính chi tiết (Hệ thống tự động)
            </h3>
            <div className="space-y-3.5 text-xs">
              {snapshot.items.map((item: any, idx: number) => {
                const basePrice = item.basePrice || 0;
                
                if (item.chargeType === "FIXED") {
                  return (
                    <div key={idx} className="bg-slate-50 p-3 rounded-xl space-y-1">
                      <div className="font-semibold text-slate-800">{item.serviceName}</div>
                      <p className="text-slate-600">
                        Phương thức tính: <code>Phí cố định hàng tháng</code>
                      </p>
                      <p className="text-slate-500 font-mono">
                        = {basePrice.toLocaleString()} đ
                      </p>
                    </div>
                  );
                }

                if (item.chargeType === "PER_PERSON") {
                  const residents = item.activeResidents || 1;
                  return (
                    <div key={idx} className="bg-slate-50 p-3 rounded-xl space-y-1">
                      <div className="font-semibold text-slate-800">{item.serviceName}</div>
                      <p className="text-slate-600">
                        Phương thức tính: <code>Đơn giá * Số người cư trú</code>
                      </p>
                      <p className="text-slate-500 font-mono">
                        = {basePrice.toLocaleString()} đ/người * {residents} người = {(basePrice * residents).toLocaleString()} đ
                      </p>
                    </div>
                  );
                }

                if (item.chargeType === "PER_QUANTITY") {
                  const qty = item.quantity || 1;
                  return (
                    <div key={idx} className="bg-slate-50 p-3 rounded-xl space-y-1">
                      <div className="font-semibold text-slate-800">{item.serviceName}</div>
                      <p className="text-slate-600">
                        Phương thức tính: <code>Đơn giá * Số lượng đăng ký</code>
                      </p>
                      <p className="text-slate-500 font-mono">
                        = {basePrice.toLocaleString()} đ * {qty} = {(basePrice * qty).toLocaleString()} đ
                      </p>
                    </div>
                  );
                }

                if (item.chargeType === "PER_INDEX" || item.chargeType === "METERED") {
                  const oldReading = item.oldReading || 0;
                  const newReading = item.newReading || 0;
                  const consumption = Math.max(0, newReading - oldReading);

                  if (item.chargeType === "PER_INDEX" || (item.pricingTiers && item.pricingTiers.length > 0)) {
                    let remaining = consumption;
                    const steps: string[] = [];
                    let totalCost = 0;

                    for (let i = 0; i < item.pricingTiers.length; i++) {
                      if (remaining <= 0) break;
                      const tier = item.pricingTiers[i];
                      const start = tier.tierStart || 0;
                      const end = tier.tierEnd;
                      const price = tier.pricePerUnit || 0;

                      const capacity = end ? (end - start) : remaining;
                      const inTier = Math.min(remaining, capacity);

                      if (inTier > 0) {
                        const cost = inTier * price;
                        totalCost += cost;
                        steps.push(
                          `Bậc ${i + 1} (${start} -> ${end ? end : "trở lên"}): ${inTier} * ${price.toLocaleString()} đ = ${cost.toLocaleString()} đ`
                        );
                        remaining -= inTier;
                      }
                    }

                    return (
                      <div key={idx} className="bg-slate-50 p-3 rounded-xl space-y-1.5">
                        <div className="font-semibold text-slate-800">{item.serviceName} (Đơn giá lũy tiến)</div>
                        <p className="text-slate-600">
                          Chỉ số cuối - Chỉ số đầu: <code>{newReading} - {oldReading} = {consumption} đơn vị</code>
                        </p>
                        <div className="pl-2.5 border-l-2 border-brand-deep/20 space-y-1 text-slate-500 font-mono">
                          {steps.map((step, sIdx) => (
                            <p key={sIdx}>{step}</p>
                          ))}
                        </div>
                        <p className="text-slate-700 font-bold font-mono text-[11px] pt-1">
                          Tổng cộng = {totalCost.toLocaleString()} đ
                        </p>
                      </div>
                    );
                  } else {
                    return (
                      <div key={idx} className="bg-slate-50 p-3 rounded-xl space-y-1">
                        <div className="font-semibold text-slate-800">{item.serviceName}</div>
                        <p className="text-slate-600">
                          Phương thức tính: <code>(Chỉ số cuối - Chỉ số đầu) * Đơn giá</code>
                        </p>
                        <p className="text-slate-500 font-mono font-bold">
                          = ({newReading} - {oldReading}) * {basePrice.toLocaleString()} đ 
                          = {consumption} * {basePrice.toLocaleString()} đ 
                          = {(consumption * basePrice).toLocaleString()} đ
                        </p>
                      </div>
                    );
                  }
                }

                return null;
              })}
            </div>
          </div>
        )}

        {/* Actions panel */}
        <div className="pt-4 flex justify-between gap-4 border-t border-slate-100">
          <div className="flex gap-2">
            <Button variant="outline" onClick={handlePrint}>
              <Printer size={16} className="mr-2" />
              In hóa đơn
            </Button>
            <Button variant="outline" onClick={handleShare}>
              <Send size={16} className="mr-2" />
              Gửi khách thuê
            </Button>
          </div>
          {isManager && (invoice.status === "PENDING" || invoice.status === "PARTIAL") && onCollectPayment && (
            <Button id="btn-manual-payment" className="bg-emerald-600 hover:bg-emerald-700 text-white" onClick={onCollectPayment}>
              <CreditCard size={16} className="mr-2" />
              Thu tiền hóa đơn
            </Button>
          )}
        </div>
      </div>
    </Modal>
  );
}

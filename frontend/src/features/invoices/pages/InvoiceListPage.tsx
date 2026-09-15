import { useState, useEffect, useCallback } from "react";
import { useSearchParams } from "react-router-dom";
import { Plus, Search, FileText, CreditCard, RefreshCw, AlertCircle, Zap } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { formatCurrency } from "@/lib/utils";
import { invoiceService, type InvoiceResult } from "@/services/invoiceService";
import { motelService, type MotelResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { Modal } from "@/components/ui/Modal";
import { PaymentModal } from "../components/PaymentModal";
import { VietQrPaymentModal } from "../components/VietQrPaymentModal";
import { InvoiceDetailModal } from "../components/InvoiceDetailModal";
import { useAuthStore } from "@/store/authStore";

const STATUS_BADGE: Record<string, React.ReactNode> = {
  PENDING: <Badge variant="warning">Chưa thanh toán</Badge>,
  PARTIAL: <Badge variant="warning">Thanh toán một phần</Badge>,
  PAID: <Badge variant="success">Đã thanh toán</Badge>,
  VOID: <Badge variant="default">Đã hủy</Badge>,
};

function GenerateInvoiceModal({
  isOpen,
  onClose,
  onSuccess,
}: {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}) {
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [motelId, setMotelId] = useState("");
  const [billingMonth, setBillingMonth] = useState(
    new Date().toISOString().slice(0, 7)
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState<{ generatedCount: number } | null>(null);

  useEffect(() => {
    if (isOpen) {
      motelService.list().then((res) => {
        setMotels(res.content);
        if (res.content.length > 0) setMotelId(String(res.content[0].id));
      });
    }
  }, [isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await invoiceService.generate({
        motelId: parseInt(motelId, 10),
        billingMonth,
      });

      // Wait/poll for the async invoice generation to write to DB
      for (let i = 0; i < 15; i++) {
        await new Promise((resolve) => setTimeout(resolve, 500));
        try {
          const listRes = await invoiceService.list(parseInt(motelId, 10), undefined, 0, 50);
          if (listRes.content && listRes.content.length > 0) {
            const hasInv = listRes.content.some(
              (inv) => inv.billingMonth && inv.billingMonth.startsWith(billingMonth)
            );
            if (hasInv) {
              break;
            }
          }
        } catch (ignored) {}
      }

      setResult({ generatedCount: 1 });
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const inputClass =
    "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Tạo hóa đơn loạt">
      {result ? (
        <div className="text-center py-6">
          <div className="p-4 bg-emerald-50 rounded-2xl inline-block mb-4">
            <Zap size={32} className="text-emerald-500" />
          </div>
          <h3 className="text-lg font-bold text-brand-ink mb-2">Tạo thành công!</h3>
          <Button id="btn-view-generated-invoices" className="mt-6" onClick={() => { setResult(null); onSuccess(); }}>
            Xem danh sách hóa đơn
          </Button>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
          )}
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Khu trọ</label>
            <select
              id="invoice-generate-motel"
              value={motelId}
              onChange={(e) => setMotelId(e.target.value)}
              required
              className={inputClass}
            >
              {motels.map((m) => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Tháng lập hóa đơn</label>
            <input
              id="invoice-generate-month"
              type="month"
              value={billingMonth}
              onChange={(e) => setBillingMonth(e.target.value)}
              required
              className={inputClass}
            />
          </div>
          <p className="text-xs text-slate-400 bg-slate-50 p-3 rounded-xl">
            💡 Hệ thống sẽ tự động tạo hóa đơn cho tất cả phòng đang có hợp đồng hoạt động.
          </p>
          <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose}>Hủy</Button>
            <Button id="btn-submit-generate-invoice" type="submit" disabled={loading}>
              {loading ? "Đang tạo..." : "Tạo hóa đơn"}
            </Button>
          </div>
        </form>
      )}
    </Modal>
  );
}

export function InvoiceListPage() {
  const { user } = useAuthStore();
  const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";

  const [searchParams, setSearchParams] = useSearchParams();
  const queryInvoiceId = searchParams.get("id");

  const [invoices, setInvoices] = useState<InvoiceResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [isGenerateOpen, setIsGenerateOpen] = useState(false);
  const [selectedInvoice, setSelectedInvoice] = useState<InvoiceResult | null>(null);
  const [invoiceDetails, setInvoiceDetails] = useState<InvoiceResult | null>(null);
  const [paymentInvoice, setPaymentInvoice] = useState<InvoiceResult | null>(null);
  const [previewQrInvoice, setPreviewQrInvoice] = useState<InvoiceResult | null>(null);
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);


  useEffect(() => {
    if (queryInvoiceId) {
      const invId = parseInt(queryInvoiceId, 10);
      if (!isNaN(invId)) {
        invoiceService.get(invId)
          .then((res) => {
            setInvoiceDetails(res);
            setSearchParams({});
          })
          .catch((err) => {
            console.error("Failed to load invoice from query param", err);
          });
      }
    }
  }, [queryInvoiceId, setSearchParams]);

  // Fetch motels for manager
  useEffect(() => {
    if (!isTenant) {
      motelService.list().then((res) => {
        setMotels(res.content);
      }).catch((err) => console.error("Error loading motels", err));
    }
  }, [isTenant]);

  const fetchInvoices = useCallback(async () => {
    setLoading(true);
    try {
      const result = isTenant
        ? await invoiceService.listMine(statusFilter || undefined, page, 20)
        : await invoiceService.list(selectedMotelId || undefined, statusFilter || undefined, page, 20);
      setInvoices(result.content);
      setTotalPages(result.totalPages);
      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter, selectedMotelId, isTenant]);


  useEffect(() => {
    fetchInvoices();
  }, [fetchInvoices]);

  useEffect(() => {
    if (selectedInvoice) {
      invoiceService.get(selectedInvoice.id)
        .then((res) => {
          setInvoiceDetails(res);
        })
        .catch((err) => console.error("Error loading invoice details", err));
    } else {
      setInvoiceDetails(null);
    }
  }, [selectedInvoice]);

  const filtered = invoices.filter((inv) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return String(inv.id).includes(q) || String(inv.roomId).includes(q);
  });

  const totalAmount = invoices.reduce((s, i) => s + (i.totalAmount ?? 0), 0);
  const paidAmount = invoices.reduce((s, i) => s + (i.paidAmount ?? 0), 0);
  const debtAmount = totalAmount - paidAmount;

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <AlertCircle size={40} className="text-red-400 mb-3" />
        <p className="text-slate-600 mb-4">{error}</p>
        <Button onClick={fetchInvoices}>Thử lại</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Hóa đơn</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý hóa đơn tiền phòng</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => fetchInvoices()} disabled={loading}>
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
          </Button>
          {!isTenant && (
            <Button
              id="btn-generate-monthly-invoice"
              variant="outline"
              onClick={() => setIsGenerateOpen(true)}
            >
              <Zap size={16} className="mr-2" />
              Tạo hóa đơn loạt
            </Button>
          )}
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: "Tổng dự kiến", value: totalAmount, color: "text-brand-ink" },
          { label: "Đã thu", value: paidAmount, color: "text-emerald-600" },
          { label: "Còn nợ", value: debtAmount, color: "text-rose-600", border: true },
        ].map((item) => (
          <div
            key={item.label}
            className={`rounded-2xl bg-white p-5 shadow-sm border border-slate-100 ${item.border ? "border-l-4 border-l-rose-400" : ""
              }`}
          >
            <p className="text-sm font-medium text-slate-500">{item.label}</p>
            <h3 className={`text-2xl font-bold mt-1 font-display ${item.color}`}>
              {formatCurrency(item.value)}
            </h3>
          </div>
        ))}
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              id="invoice-search"
              type="text"
              placeholder="Tìm theo phòng, mã HĐ..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="h-10 w-full rounded-xl border border-slate-200 bg-white pl-10 pr-4 text-sm focus:border-brand-deep focus:outline-none focus:ring-2 focus:ring-brand-deep/20 transition-all"
            />
          </div>
          <div className="flex items-center gap-3 flex-wrap w-full sm:w-auto">
            {!isTenant && (
              <select
                id="invoice-motel-filter"
                value={selectedMotelId ?? ""}
                onChange={(e) => { setSelectedMotelId(e.target.value ? Number(e.target.value) : null); setPage(0); }}
                className="h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 bg-white"
              >
                <option value="">Tất cả khu trọ</option>
                {motels.map((m) => (
                  <option key={m.id} value={m.id}>{m.name}</option>
                ))}
              </select>
            )}
            <select
              id="invoice-status-filter"
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(0); }}
              className="h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 bg-white"
            >
              <option value="">Tất cả trạng thái</option>
              <option value="PENDING">Chưa thanh toán</option>
              <option value="PARTIAL">Một phần</option>
              <option value="PAID">Đã thanh toán</option>
              <option value="VOID">Đã hủy</option>
            </select>
          </div>

        </div>

        {loading ? (
          <div className="p-12 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-deep border-t-transparent" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-16 flex flex-col items-center text-center">
            <FileText size={40} className="text-slate-200 mb-3" />
            <p className="text-slate-500 font-medium">Chưa có hóa đơn nào</p>
            <p className="text-sm text-slate-400 mt-1 mb-4">Tạo hóa đơn loạt để bắt đầu</p>
            <Button id="btn-generate-monthly-invoice" onClick={() => setIsGenerateOpen(true)}>
              <Zap size={16} className="mr-2" />
              Tạo hóa đơn
            </Button>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Mã HĐ & Phòng</TableHead>
                <TableHead>Kỳ HĐ</TableHead>
                <TableHead>Tổng tiền</TableHead>
                <TableHead>Đã thu</TableHead>
                <TableHead>Trạng thái</TableHead>
                <TableHead className="text-right">Thao tác</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((invoice) => (
                <TableRow key={invoice.id} className="hover:bg-slate-50/50 transition-colors">
                  <TableCell>
                    <div className="font-mono text-xs text-slate-400">#{invoice.id}</div>
                    <div className="font-medium text-brand-deep">
                      {invoice.roomNumber ? `P.${invoice.roomNumber}` : `Phòng ${invoice.roomId}`}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm text-slate-700">
                      {invoice.billingMonth
                        ? new Date(invoice.billingMonth).toLocaleDateString("vi-VN", { month: "long", year: "numeric" })
                        : "-"}
                    </div>
                    {invoice.dueDate && (
                      <div className="text-xs text-slate-400">
                        Hạn: {new Date(invoice.dueDate).toLocaleDateString("vi-VN")}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="font-bold text-brand-ink">{formatCurrency(invoice.totalAmount)}</div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm text-emerald-700 font-medium">{formatCurrency(invoice.paidAmount)}</div>
                  </TableCell>
                  <TableCell>{STATUS_BADGE[invoice.status] ?? <Badge>{invoice.status}</Badge>}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-2">
                      {(invoice.status === "PENDING" || invoice.status === "PARTIAL") && (
                        <>
                          {isTenant ? (
                            <Button
                              id="btn-preview-qr-invoice"
                              variant="outline"
                              size="sm"
                              className="text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 border-emerald-200"
                              onClick={() => setPaymentInvoice(invoice)}
                            >
                              <CreditCard size={14} className="mr-1.5" />
                              Thanh toán bằng VietQR ➜
                            </Button>
                          ) : (
                            <>
                              <Button
                                id="btn-preview-qr-invoice"
                                variant="outline"
                                size="sm"
                                className="text-brand-deep border-brand-deep hover:bg-brand-deep/5"
                                onClick={() => setPreviewQrInvoice(invoice)}
                              >
                                Mã QR
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                className="text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 border-emerald-200"
                                onClick={() => setPaymentInvoice(invoice)}
                              >
                                <CreditCard size={14} className="mr-1.5" />
                                Thu tiền
                              </Button>
                            </>
                          )}
                        </>
                      )}
                      <Button
                        id="btn-invoice-detail"
                        variant="outline"
                        size="sm"
                        onClick={() => setSelectedInvoice(invoice)}
                      >
                        Chi tiết
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}

        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-100 flex justify-center gap-2">
            <Button variant="outline" size="sm" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>
              Trước
            </Button>
            <span className="px-4 py-1.5 text-sm text-slate-600">{page + 1} / {totalPages}</span>
            <Button variant="outline" size="sm" disabled={page >= totalPages - 1} onClick={() => setPage((p) => p + 1)}>
              Sau
            </Button>
          </div>
        )}
      </div>

      {selectedInvoice && (
        <InvoiceDetailModal
          isOpen={!!selectedInvoice}
          onClose={() => setSelectedInvoice(null)}
          invoice={invoiceDetails}
          isManager={!isTenant}
          onCollectPayment={() => {
            setSelectedInvoice(null);
            setPaymentInvoice(selectedInvoice);
          }}
        />
      )}

      <GenerateInvoiceModal
        isOpen={isGenerateOpen}
        onClose={() => setIsGenerateOpen(false)}
        onSuccess={() => { setIsGenerateOpen(false); fetchInvoices(); }}
      />

      {paymentInvoice && isTenant ? (
        <VietQrPaymentModal
          isOpen={!!paymentInvoice}
          onClose={() => setPaymentInvoice(null)}
          invoiceId={paymentInvoice.id}
          onSuccess={() => { setPaymentInvoice(null); fetchInvoices(); }}
        />
      ) : paymentInvoice ? (
        <PaymentModal
          isOpen={!!paymentInvoice}
          onClose={() => setPaymentInvoice(null)}
          invoiceId={paymentInvoice.id}
          totalDebt={paymentInvoice.totalAmount - (paymentInvoice.paidAmount || 0)}
          onSuccess={() => { setPaymentInvoice(null); fetchInvoices(); }}
        />
      ) : null}

      {previewQrInvoice && (
        <VietQrPaymentModal
          isOpen={!!previewQrInvoice}
          onClose={() => setPreviewQrInvoice(null)}
          invoiceId={previewQrInvoice.id}
          onSuccess={() => { setPreviewQrInvoice(null); fetchInvoices(); }}
        />
      )}
    </div>
  );
}

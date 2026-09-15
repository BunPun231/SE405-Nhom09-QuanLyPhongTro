import { useState, useEffect, useCallback } from "react";
import { Plus, Edit2, Trash2, RefreshCw, AlertCircle, Zap, Building2, Tag } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { formatCurrency, formatVnStyle, stripVnStyle } from "@/lib/utils";
import { serviceService, type ServiceResult, type ServiceCreateRequest, type ServiceUpdateRequest, type ServiceTierPricing } from "@/services/serviceService";
import { motelService, type MotelResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { AssignServiceModal } from "../components/AssignServiceModal";
import { useTourGuide } from "@/hooks/useTourGuide";



const CHARGE_TYPE_LABEL: Record<string, string> = {
  FIXED: "Cố định",
  PER_PERSON: "Theo người",
  PER_INDEX: "Theo chỉ số (Điện/Nước)",
  PER_QUANTITY: "Theo số lượng",
  METERED: "Theo chỉ số",
  TIERED: "Lũy tiến / Bậc thang",
};

const CHARGE_TYPE_COLOR: Record<string, string> = {
  FIXED: "bg-violet-100 text-violet-700",
  PER_PERSON: "bg-orange-100 text-orange-700",
  PER_INDEX: "bg-blue-100 text-blue-700",
  PER_QUANTITY: "bg-cyan-100 text-cyan-700",
  METERED: "bg-blue-100 text-blue-700",
  TIERED: "bg-emerald-100 text-emerald-700",
};

// ============ SERVICE FORM MODAL ============
function ServiceFormModal({
  isOpen,
  onClose,
  onSuccess,
  motelId,
  editing,
}: {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  motelId: number;
  editing?: ServiceResult;
}) {
  const { activeSubStepId, setActiveSubStepId } = useTourGuide();
  const [form, setForm] = useState<ServiceCreateRequest>({
    name: "",
    chargeType: "FIXED",
    unit: "",
    mandatory: false,
    basePrice: 0,
    pricingTiers: [],
  });
  const [useTiered, setUseTiered] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [suggestions, setSuggestions] = useState<{ name: string; chargeType: string; unit: string; mandatory: boolean }[]>([]);
  const [showSuggestions, setShowSuggestions] = useState(false);

  useEffect(() => {
    if (editing) {
      let initialChargeType = editing.chargeType;
      if (editing.chargeType === "TIERED") {
        initialChargeType = "PER_INDEX";
      }
      setForm({
        name: editing.name,
        chargeType: initialChargeType,
        unit: editing.unit ?? "",
        mandatory: editing.mandatory,
        basePrice: editing.basePrice ?? 0,
        pricingTiers: editing.pricingTiers ?? [],
      });
      setUseTiered(editing.chargeType === "PER_INDEX" || editing.chargeType === "TIERED" || (editing.pricingTiers && editing.pricingTiers.length > 0) || false);
    } else {
      setForm({ name: "", chargeType: "FIXED", unit: "", mandatory: false, basePrice: 0, pricingTiers: [] });
      setUseTiered(false);
    }
    setError("");
  }, [editing, isOpen]);

  useEffect(() => {
    if (isOpen) {
      const loadSuggestions = async () => {
        try {
          const motelList = await motelService.list();
          const allServicesPromises = motelList.content.map(m => serviceService.list(m.id));
          const allServicesNested = await Promise.all(allServicesPromises);
          const allServices = allServicesNested.flat();

          const uniqueMap = new Map<string, { name: string; chargeType: string; unit: string; mandatory: boolean }>();

          const defaults = [
            { name: "Điện", chargeType: "METERED", unit: "kWh", mandatory: true },
            { name: "Nước sinh hoạt", chargeType: "METERED", unit: "m³", mandatory: true },
            { name: "Mạng Wifi / Internet", chargeType: "FIXED", unit: "tháng", mandatory: false },
            { name: "Rác thải", chargeType: "FIXED", unit: "tháng", mandatory: true },
            { name: "Phí dịch vụ chung", chargeType: "FIXED", unit: "tháng", mandatory: false },
            { name: "Gửi xe", chargeType: "PER_QUANTITY", unit: "xe", mandatory: false },
          ];
          defaults.forEach(d => uniqueMap.set(d.name.toLowerCase(), d));

          allServices.forEach(s => {
            if (s.name) {
              const chargeType = s.chargeType === "TIERED" ? "PER_INDEX" : s.chargeType;
              uniqueMap.set(s.name.toLowerCase(), {
                name: s.name,
                chargeType,
                unit: s.unit ?? "",
                mandatory: s.mandatory,
              });
            }
          });

          setSuggestions(Array.from(uniqueMap.values()));
        } catch (err) {
          console.error("Failed to load service suggestions", err);
        }
      };
      loadSuggestions();
    }
  }, [isOpen]);

  const filteredSuggestions = suggestions.filter(s =>
    s.name.toLowerCase().includes(form.name.toLowerCase()) &&
    s.name.toLowerCase() !== form.name.toLowerCase()
  );

  const handleSelectSuggestion = (s: typeof suggestions[0]) => {
    const isTiered = s.chargeType === "PER_INDEX";
    setForm((prev: ServiceCreateRequest) => ({
      ...prev,
      name: s.name,
      chargeType: s.chargeType,
      unit: s.unit,
      mandatory: s.mandatory,
    }));
    setUseTiered(isTiered);
    setShowSuggestions(false);
  };

  const handleAddTier = () => {
    setForm((prev: ServiceCreateRequest) => {
      const currentTiers = prev.pricingTiers || [];
      const lastTier = currentTiers[currentTiers.length - 1];
      const nextStart = lastTier ? ((lastTier.tierEnd || 0) + 1) : 0;
      return {
        ...prev,
        pricingTiers: [
          ...currentTiers,
          { tierStart: nextStart, tierEnd: 0, pricePerUnit: 0 },
        ],
      };
    });
  };

  const handleRemoveTier = (index: number) => {
    setForm((prev: ServiceCreateRequest) => ({
      ...prev,
      pricingTiers: (prev.pricingTiers || []).filter((_, i: number) => i !== index),
    }));
  };

  const handleTierChange = (index: number, field: string, val: number) => {
    setForm((prev: ServiceCreateRequest) => {
      const tiers = [...(prev.pricingTiers || [])];
      tiers[index] = { ...tiers[index], [field]: val };
      if (field === "tierEnd" && index < tiers.length - 1) {
        tiers[index + 1] = { ...tiers[index + 1], tierStart: val };
      }
      return { ...prev, pricingTiers: tiers };
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const isIndexBased = form.chargeType === "PER_INDEX" || form.chargeType === "METERED";
      const payload: ServiceCreateRequest = {
        ...form,
        pricingTiers: (useTiered && isIndexBased) ? form.pricingTiers : [],
        basePrice: (useTiered && isIndexBased) ? 0 : form.basePrice,
      };

      if (editing) {
        await serviceService.update(motelId, editing.id, payload as ServiceUpdateRequest);
      } else {
        await serviceService.create(motelId, payload);
      }
      onSuccess();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={editing ? "Cập nhật dịch vụ" : "Thêm dịch vụ mới"} size={(useTiered && form.chargeType === "PER_INDEX") ? "lg" : "md"}>
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
        )}
        <div className="space-y-1 relative">
          <label className="text-sm font-medium text-slate-700">Tên dịch vụ *</label>
          <input
            id="input-service-name"
            type="text"
            value={form.name}
            onChange={(e) => {
              setForm({ ...form, name: e.target.value });
              setShowSuggestions(true);
            }}
            onFocus={() => setShowSuggestions(true)}
            onBlur={() => {
              setTimeout(() => setShowSuggestions(false), 200);
            }}
            required
            placeholder="VD: Điện, Nước, Internet..."
            className={inputClass}
            autoComplete="off"
          />
          {showSuggestions && filteredSuggestions.length > 0 && (
            <div className="absolute left-0 right-0 z-50 mt-1 max-h-48 overflow-y-auto bg-white border border-slate-200 rounded-xl shadow-lg divide-y divide-slate-100">
              {filteredSuggestions.map((s, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => handleSelectSuggestion(s)}
                  className="w-full text-left px-4 py-2 hover:bg-slate-50 transition-colors text-sm text-slate-700 flex justify-between items-center"
                >
                  <span className="font-medium">{s.name}</span>
                  <span className="text-xs text-slate-400 bg-slate-100 px-2 py-0.5 rounded-md">
                    {CHARGE_TYPE_LABEL[s.chargeType] ?? s.chargeType} ({s.unit})
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Loại tính phí *</label>
            <select
              id="select-charge-type"
              value={form.chargeType}
              onChange={(e) => {
                const val = e.target.value;
                setForm({ ...form, chargeType: val });
                if (val === "PER_INDEX") {
                  setUseTiered(true);
                } else if (val === "METERED") {
                  setUseTiered(false);
                }
                if (activeSubStepId === "3.3") {
                  setActiveSubStepId("3.4");
                  localStorage.setItem("onboarding_substep", "3.4");
                }
              }}
              className={inputClass}
            >
              <option value="FIXED">Cố định (phí hàng tháng)</option>
              <option value="PER_PERSON">Theo người</option>
              <option value="PER_QUANTITY">Theo số lượng</option>
              <option value="PER_INDEX">Tính điện nước theo chỉ số bậc thang</option>
              <option value="METERED">Tính điện nước theo giá cố định</option>
            </select>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Đơn vị</label>
            <input
              id="service-unit"
              type="text"
              value={form.unit ?? ""}
              onChange={(e) => setForm({ ...form, unit: e.target.value })}
              placeholder="kWh, m³, tháng..."
              className={inputClass}
            />
          </div>
        </div>



        {!useTiered ? (
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">
              {form.chargeType === "FIXED" ? "Phí cố định (đ/tháng)" : "Đơn giá cơ bản (đ/đơn vị)"} *
            </label>
            <input
              id="input-service-price"
              type="text"
              value={formatVnStyle(form.basePrice)}
              onChange={(e) => setForm({ ...form, basePrice: Number(stripVnStyle(e.target.value)) || 0 })}
              required
              placeholder="0"
              className={inputClass}
            />
          </div>
        ) : (
          <div className="space-y-3 bg-slate-50 p-4 rounded-xl border border-slate-200">
            <div className="flex justify-between items-center">
              <label className="text-sm font-bold text-slate-700">Cấu hình bậc giá lũy tiến</label>
              <Button type="button" size="sm" onClick={handleAddTier}>+ Thêm bậc</Button>
            </div>
            <div className="space-y-2">
              {(form.pricingTiers || []).map((tier: ServiceTierPricing, index: number) => (
                <div key={index} className="grid grid-cols-4 gap-2 items-center">
                  <input
                    type="number"
                    value={tier.tierStart ?? 0}
                    placeholder="Từ"
                    onChange={(e) => handleTierChange(index, "tierStart", Number(e.target.value))}
                    className={`${inputClass} !py-1.5 ${index > 0 ? "bg-slate-100/70 cursor-not-allowed text-slate-500" : ""}`}
                    readOnly={index > 0}
                  />
                  <input
                    type="number"
                    value={tier.tierEnd ?? 0}
                    placeholder="Đến"
                    onChange={(e) => handleTierChange(index, "tierEnd", Number(e.target.value))}
                    className={`${inputClass} !py-1.5`}
                  />
                  <input
                    type="text"
                    value={formatVnStyle(tier.pricePerUnit)}
                    placeholder="Đơn giá"
                    onChange={(e) => handleTierChange(index, "pricePerUnit", Number(stripVnStyle(e.target.value)) || 0)}
                    className={`${inputClass} !py-1.5`}
                  />
                  <Button type="button" variant="danger" size="sm" onClick={() => handleRemoveTier(index)}>Xóa</Button>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-100">
          <input
            id="checkbox-is-mandatory"
            type="checkbox"
            checked={form.mandatory ?? false}
            onChange={(e) => setForm({ ...form, mandatory: e.target.checked })}
            className="w-4 h-4 text-brand-deep rounded border-slate-300"
          />
          <div>
            <label htmlFor="checkbox-is-mandatory" className="text-sm font-medium text-slate-700 cursor-pointer">
              Dịch vụ bắt buộc
            </label>
            <p className="text-xs text-slate-400">Tự động áp dụng cho tất cả hợp đồng</p>
          </div>
        </div>
        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose} disabled={loading}>Hủy</Button>
          <Button id="btn-submit-service" type="submit" disabled={loading}>
            {loading ? "Đang lưu..." : editing ? "Cập nhật" : "Thêm dịch vụ"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

// ============ MAIN PAGE ============
export function ServiceListPage() {
  const { refreshStatus } = useTourGuide();
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [services, setServices] = useState<ServiceResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingService, setEditingService] = useState<ServiceResult | undefined>();
  const [assigningService, setAssigningService] = useState<ServiceResult | undefined>();

  useEffect(() => {
    motelService.list().then((r) => {
      setMotels(r.content);
      if (r.content.length > 0) setSelectedMotelId(r.content[0].id);
    });
  }, []);

  const fetchServices = useCallback(async () => {
    if (!selectedMotelId) return;
    setLoading(true);
    try {
      const result = await serviceService.list(selectedMotelId);
      setServices(result);
      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [selectedMotelId]);

  useEffect(() => {
    fetchServices();
  }, [fetchServices]);

  const handleDelete = async (svc: ServiceResult) => {
    if (!confirm(`Xóa dịch vụ "${svc.name}"?`)) return;
    try {
      await serviceService.delete(selectedMotelId!, svc.id);
      fetchServices();
    } catch (err) {
      alert(extractError(err));
    }
  };

  const mandatoryServices = services.filter((s) => s.mandatory);
  const optionalServices = services.filter((s) => !s.mandatory);

  const selectClass = "h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 bg-white";

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Dịch vụ & Tiện ích</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý các dịch vụ áp dụng cho phòng</p>
        </div>
        <div className="flex gap-2">
          <select
            id="service-motel-select"
            value={selectedMotelId ?? ""}
            onChange={(e) => setSelectedMotelId(Number(e.target.value))}
            className={selectClass}
          >
            {motels.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
          </select>
          <Button variant="outline" onClick={fetchServices} disabled={loading}>
            <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
          </Button>
          <Button
            id="btn-create-service"
            onClick={() => { setEditingService(undefined); setIsFormOpen(true); }}
            disabled={!selectedMotelId}
          >
            <Plus size={16} className="mr-2" />
            Thêm dịch vụ
          </Button>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid gap-4 md:grid-cols-3">
        {[
          { label: "Tổng dịch vụ", value: services.length, icon: Zap, bg: "bg-violet-100", color: "text-violet-600" },
          { label: "Bắt buộc", value: mandatoryServices.length, icon: Tag, bg: "bg-rose-100", color: "text-rose-600" },
          { label: "Tùy chọn", value: optionalServices.length, icon: Building2, bg: "bg-blue-100", color: "text-blue-600" },
        ].map((item) => (
          <div key={item.label} className="rounded-2xl bg-white p-5 shadow-sm border border-slate-100 flex items-center gap-4">
            <div className={`p-3 ${item.bg} rounded-xl`}>
              <item.icon size={22} className={item.color} />
            </div>
            <div>
              <p className="text-sm font-medium text-slate-500">{item.label}</p>
              <h3 className="text-2xl font-bold text-brand-ink mt-0.5">{item.value}</h3>
            </div>
          </div>
        ))}
      </div>

      {error && (
        <div className="flex items-center gap-3 p-4 rounded-xl bg-red-50 border border-red-100 text-red-700 text-sm">
          <AlertCircle size={18} />
          {error}
          <Button size="sm" variant="outline" className="ml-auto" onClick={fetchServices}>Thử lại</Button>
        </div>
      )}

      {loading ? (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <div key={i} className="h-44 rounded-2xl bg-slate-100 animate-pulse" />
          ))}
        </div>
      ) : services.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-24 bg-white rounded-2xl border border-dashed border-slate-200">
          <Zap size={40} className="text-slate-200 mb-4" />
          <h3 className="font-semibold text-slate-600 mb-1">Chưa có dịch vụ nào</h3>
          <p className="text-sm text-slate-400 mb-5">Thêm điện, nước, internet... để tự động tính phí hóa đơn</p>
          <Button onClick={() => { setEditingService(undefined); setIsFormOpen(true); }}>
            <Plus size={16} className="mr-2" />
            Thêm dịch vụ đầu tiên
          </Button>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Mandatory */}
          {mandatoryServices.length > 0 && (
            <div>
              <div className="flex items-center gap-3 mb-3">
                <h2 className="text-sm font-semibold text-slate-600 uppercase tracking-wider">Dịch vụ bắt buộc</h2>
                <div className="flex-1 h-px bg-slate-200" />
              </div>
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {mandatoryServices.map((svc) => (
                  <ServiceCard
                    key={svc.id}
                    service={svc}
                    onEdit={() => { setEditingService(svc); setIsFormOpen(true); }}
                    onDelete={() => handleDelete(svc)}
                    onAssign={() => setAssigningService(svc)}
                  />
                ))}
              </div>
            </div>
          )}

          {/* Optional */}
          {optionalServices.length > 0 && (
            <div>
              <div className="flex items-center gap-3 mb-3">
                <h2 className="text-sm font-semibold text-slate-600 uppercase tracking-wider">Dịch vụ tùy chọn</h2>
                <div className="flex-1 h-px bg-slate-200" />
              </div>
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {optionalServices.map((svc) => (
                  <ServiceCard
                    key={svc.id}
                    service={svc}
                    onEdit={() => { setEditingService(svc); setIsFormOpen(true); }}
                    onDelete={() => handleDelete(svc)}
                    onAssign={() => setAssigningService(svc)}
                  />
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      <ServiceFormModal
        isOpen={isFormOpen}
        onClose={() => setIsFormOpen(false)}
        onSuccess={() => { setIsFormOpen(false); fetchServices(); refreshStatus(); }}
        motelId={selectedMotelId!}
        editing={editingService}
      />
      {assigningService && (
        <AssignServiceModal
          isOpen={!!assigningService}
          onClose={() => setAssigningService(undefined)}
          motelId={selectedMotelId!}
          service={assigningService}
        />
      )}
    </div>
  );
}

// ============ SERVICE CARD ============
function ServiceCard({
  service,
  onEdit,
  onDelete,
  onAssign,
}: {
  service: ServiceResult;
  onEdit: () => void;
  onDelete: () => void;
  onAssign: () => void;
}) {
  const isTieredPricing = service.chargeType === "PER_INDEX" || (service.pricingTiers && service.pricingTiers.length > 0);

  return (
    <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm hover:shadow-md transition-all group">
      <div className="flex justify-between items-start mb-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="font-bold text-brand-ink truncate">{service.name}</h3>
            {service.mandatory && (
              <span className="text-xs bg-rose-100 text-rose-600 px-2 py-0.5 rounded-full flex-shrink-0">Bắt buộc</span>
            )}
          </div>
          <span className={`text-xs px-2 py-0.5 rounded-lg font-medium ${isTieredPricing
            ? CHARGE_TYPE_COLOR["TIERED"]
            : (CHARGE_TYPE_COLOR[service.chargeType] ?? "bg-slate-100 text-slate-500")
            }`}>
            {isTieredPricing
              ? CHARGE_TYPE_LABEL["TIERED"]
              : (CHARGE_TYPE_LABEL[service.chargeType] ?? service.chargeType)}
          </span>
        </div>
      </div>

      <div className="space-y-2 text-sm mb-5">
        <div className="flex justify-between items-center">
          <span className="text-slate-400">Đơn giá</span>
          <span className="font-bold text-brand-deep text-base">
            {isTieredPricing ? (
              <span>Theo bậc thang</span>
            ) : (
              <>
                {formatCurrency(service.basePrice ?? 0)}
                {service.unit && service.unit !== "string" && service.unit !== "adqqgaf" ? (
                  <span className="text-slate-400 font-normal text-xs">/{service.unit}</span>
                ) : (
                  <span className="text-slate-400 font-normal text-xs">
                    /{service.name.toLowerCase().includes("nước") ? "khối" : service.name.toLowerCase().includes("điện") ? "số" : "tháng"}
                  </span>
                )}
              </>
            )}
          </span>
        </div>
        {isTieredPricing && service.pricingTiers && (
          <div className="text-xs text-slate-500 bg-slate-50 rounded-xl p-2.5 space-y-1 mt-2 border border-slate-100">
            {service.pricingTiers.map((tier: ServiceTierPricing, idx: number) => (
              <div key={idx} className="flex justify-between items-center">
                <span>
                  Bậc {idx + 1}: {tier.tierStart} - {tier.tierEnd ? `${tier.tierEnd} ${service.unit ?? "đơn vị"}` : "trở lên"}
                </span>
                <span className="font-semibold text-slate-700">{formatCurrency(tier.pricePerUnit)}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="flex gap-2">
        <Button variant="outline" className="flex-1" size="sm" onClick={onAssign}>
          Áp dụng
        </Button>
        <Button variant="outline" className="flex-1" size="sm" onClick={onEdit}>
          <Edit2 size={14} className="mr-1.5" />
          Cập nhật
        </Button>
        <Button
          variant="danger"
          className="w-9 px-0 flex items-center justify-center"
          size="sm"
          onClick={onDelete}
        >
          <Trash2 size={14} />
        </Button>
      </div>
    </div>
  );
}

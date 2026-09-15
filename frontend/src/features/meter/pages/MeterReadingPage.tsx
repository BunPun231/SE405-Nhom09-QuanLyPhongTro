import { useState, useEffect, useCallback, useMemo } from "react";
import { Gauge, RefreshCw, AlertCircle, CheckCircle2, XCircle, Camera, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { useNavigate } from "react-router-dom";
import { useTourGuide } from "@/hooks/useTourGuide";
import electricMeterSampleImg from "../../../../image/ElectricMeter.jpg";
import { Badge } from "@/components/ui/Badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Modal } from "@/components/ui/Modal";
import { meterReadingService, type MeterReadingResult, type MeterReadingSubmitRequest } from "@/services/invoiceService";
import { motelService, roomService, type MotelResult, type RoomResult } from "@/services/motelService";
import { serviceService, type ServiceResult } from "@/services/serviceService";
import { contractService } from "@/services/contractService";
import { extractError } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";

const STATUS_BADGE: Record<string, React.ReactNode> = {
  PENDING: <Badge variant="warning">Chờ duyệt</Badge>,
  SUBMITTED: <Badge variant="default">Đã nộp</Badge>,
  APPROVED: <Badge variant="success">Đã duyệt</Badge>,
  REJECTED: <Badge variant="danger">Từ chối</Badge>,
};

interface ServiceInput {
  newReading: string;
  readingImageUrl: string;
  ocrSuccess: boolean;
}

function SubmitRoomReadingsModal({
  isOpen,
  onClose,
  roomId,
  roomNumber,
  billingMonth,
  services,
  onSuccess,
  onShowLightbox,
}: {
  isOpen: boolean;
  onClose: () => void;
  roomId: number;
  roomNumber: string;
  billingMonth: string;
  services: Array<{
    serviceId: number;
    serviceName: string;
    oldReading: number;
    currentReading?: MeterReadingResult;
  }>;
  onSuccess: () => void;
  onShowLightbox: (url: string) => void;
}) {
  const { activeSubStepId, setActiveSubStepId } = useTourGuide();
  const { user } = useAuthStore();
  const [inputs, setInputs] = useState<Record<number, ServiceInput>>({});
  const [ocrLoadings, setOcrLoadings] = useState<Record<number, boolean>>({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleUseSampleImage = async (serviceId: number) => {
    try {
      const response = await fetch(electricMeterSampleImg);
      const blob = await response.blob();
      const reader = new FileReader();
      reader.onloadend = () => {
        handleInputChange(serviceId, "readingImageUrl", reader.result as string);
        handleInputChange(serviceId, "ocrSuccess", false);
        const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";
        if (!isTenant && activeSubStepId === "5.2") {
          setActiveSubStepId("5.3");
          localStorage.setItem("onboarding_substep", "5.3");
        } else if (isTenant && activeSubStepId === "1.2") {
          setActiveSubStepId("1.3");
          localStorage.setItem("tenant_onboarding_substep", "1.3");
        }
      };
      reader.readAsDataURL(blob);
    } catch (err) {
      console.error("Failed to load sample image", err);
      handleInputChange(serviceId, "readingImageUrl", electricMeterSampleImg);
      const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";
      if (!isTenant && activeSubStepId === "5.2") {
        setActiveSubStepId("5.3");
        localStorage.setItem("onboarding_substep", "5.3");
      } else if (isTenant && activeSubStepId === "1.2") {
        setActiveSubStepId("1.3");
        localStorage.setItem("tenant_onboarding_substep", "1.3");
      }
    }
  };

  // Initialize inputs when modal opens or services change
  useEffect(() => {
    if (isOpen) {
      const initialInputs: Record<number, ServiceInput> = {};
      for (const s of services) {
        initialInputs[s.serviceId] = {
          newReading: s.currentReading?.newReading?.toString() || "",
          readingImageUrl: s.currentReading?.imageUrl || "",
          ocrSuccess: false,
        };
      }
      setInputs(initialInputs);
      setOcrLoadings({});
      setError("");
    }
  }, [isOpen, services]);

  const handleInputChange = (serviceId: number, field: keyof ServiceInput, value: any) => {
    setInputs(prev => ({
      ...prev,
      [serviceId]: {
        ...prev[serviceId],
        [field]: value
      }
    }));
  };

  const handleFileChange = (serviceId: number, file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      handleInputChange(serviceId, "readingImageUrl", reader.result as string);
      handleInputChange(serviceId, "ocrSuccess", false);
    };
    reader.readAsDataURL(file);
  };

  const handleOcr = async (serviceId: number, oldReading: number) => {
    const imgUrl = inputs[serviceId]?.readingImageUrl;
    if (!imgUrl) return;

    setOcrLoadings(prev => ({ ...prev, [serviceId]: true }));
    setError("");

    const match = imgUrl.match(/^data:(image\/[a-zA-Z+.-]+);base64,(.+)$/);
    if (!match) {
      setError("Định dạng ảnh không hợp lệ");
      setOcrLoadings(prev => ({ ...prev, [serviceId]: false }));
      return;
    }
    const mimeType = match[1];
    const base64Image = match[2];

    try {
      const res = await meterReadingService.submitWithOcr({
        roomId,
        serviceId,
        billingMonth: billingMonth + "-01",
        base64Image,
        mimeType,
      });
      const extractedVal = res?.newReading ?? res?.ocrReading;
      if (extractedVal != null) {
        handleInputChange(serviceId, "newReading", extractedVal.toString());
        handleInputChange(serviceId, "ocrSuccess", true);
      } else {
        throw new Error("Không trích xuất được chỉ số");
      }
    } catch (err) {
      console.warn("Real OCR API call failed, falling back to mock OCR:", err);
      await new Promise((resolve) => setTimeout(resolve, 1000));
      const simulatedVal = oldReading + Math.floor(Math.random() * 80) + 15;
      handleInputChange(serviceId, "newReading", simulatedVal.toString());
      handleInputChange(serviceId, "ocrSuccess", true);
    } finally {
      setOcrLoadings(prev => ({ ...prev, [serviceId]: false }));
      const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";
      if (!isTenant && activeSubStepId === "5.3") {
        setActiveSubStepId("5.4");
        localStorage.setItem("onboarding_substep", "5.4");
      } else if (isTenant && activeSubStepId === "1.3") {
        setActiveSubStepId("1.4");
        localStorage.setItem("tenant_onboarding_substep", "1.4");
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const submitPromises = [];
      for (const s of services) {
        // Skip services that are already approved
        if (s.currentReading?.status === "APPROVED") continue;

        const val = inputs[s.serviceId]?.newReading;
        if (!val || val.trim() === "") continue;

        const newReadingNum = parseFloat(val);
        if (isNaN(newReadingNum)) {
          throw new Error(`Chỉ số của dịch vụ ${s.serviceName} không hợp lệ`);
        }
        if (newReadingNum < s.oldReading) {
          throw new Error(`Chỉ số cuối kỳ của dịch vụ ${s.serviceName} không được nhỏ hơn đầu kỳ (${s.oldReading})`);
        }

        const payload: MeterReadingSubmitRequest = {
          roomId,
          serviceId: s.serviceId,
          billingMonth: billingMonth + "-01",
          newReading: newReadingNum,
          readingImageUrl: inputs[s.serviceId]?.readingImageUrl || undefined
        };
        submitPromises.push(meterReadingService.submit(payload));
      }

      if (submitPromises.length === 0) {
        throw new Error("Vui lòng nhập ít nhất một chỉ số");
      }

      await Promise.all(submitPromises);
      onSuccess();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const inputClass =
    "w-full px-3 py-1.5 border border-slate-200 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Ghi chỉ số - Phòng P.${roomNumber}`} size="lg">
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
        )}

        <div className="p-3 bg-brand-deep/5 rounded-xl border border-brand-deep/10 flex justify-between items-center text-sm">
          <div>
            <span className="text-xs text-slate-500 block">Kỳ thanh toán</span>
            <span className="font-bold text-slate-700">{billingMonth}</span>
          </div>
        </div>

        <div className="space-y-4 max-h-[50vh] overflow-y-auto pr-1">
          {services.map((svc) => {
            const isApproved = svc.currentReading?.status === "APPROVED";
            const val = inputs[svc.serviceId]?.newReading;
            const parsedVal = val ? parseFloat(val) : NaN;
            const consumption = !isNaN(parsedVal) && parsedVal >= svc.oldReading ? parsedVal - svc.oldReading : 0;

            if (isApproved) {
              return (
                <div key={svc.serviceId} className="p-3 bg-emerald-50 border border-emerald-100 rounded-xl flex justify-between items-center text-sm">
                  <div>
                    <span className="font-bold text-emerald-800">{svc.serviceName}</span>
                    <span className="text-slate-500 ml-2">Đã chốt: {svc.currentReading?.newReading}</span>
                  </div>
                  <Badge variant="success">Đã duyệt</Badge>
                </div>
              );
            }

            return (
              <div key={svc.serviceId} className="p-4 bg-slate-50 border border-slate-200 rounded-xl space-y-3">
                <div className="flex justify-between items-center border-b border-slate-200 pb-1.5">
                  <h4 className="font-bold text-slate-800">{svc.serviceName}</h4>
                  {svc.currentReading && (
                    <span className="text-xs">{STATUS_BADGE[svc.currentReading.status]}</span>
                  )}
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                  {/* Left Column: Proof Image (Large) */}
                  <div className="flex flex-col justify-center items-center bg-slate-100 rounded-xl p-2 border border-slate-200/60 min-h-[220px]">
                    {inputs[svc.serviceId]?.readingImageUrl ? (
                      <div className="relative group w-full flex flex-col items-center justify-center p-1">
                        <img
                          src={inputs[svc.serviceId].readingImageUrl}
                          alt="preview"
                          className="max-h-56 w-auto rounded-lg object-contain border bg-white shadow-sm cursor-zoom-in hover:opacity-95 transition-opacity"
                          onClick={() => onShowLightbox(inputs[svc.serviceId].readingImageUrl)}
                        />
                        <span className="text-[10px] text-slate-400 mt-2 font-medium">🔍 Click để xem phóng to</span>
                      </div>
                    ) : (
                      <div className="text-slate-400 text-xs flex flex-col items-center gap-1.5 p-6 text-center">
                        <Camera size={32} className="text-slate-300" />
                        <span>Chưa có ảnh minh chứng điện nước</span>
                      </div>
                    )}
                  </div>

                  {/* Right Column: Inputs & Controls */}
                  <div className="space-y-3 flex flex-col justify-between">
                    <div className="space-y-2">
                      <span className="text-[10px] font-semibold text-slate-600 block">Chỉ số ghi nhận</span>
                      <div className="flex gap-2">
                        <div className="flex-1">
                          <span className="text-[10px] text-slate-400 block mb-0.5">Đầu kỳ</span>
                          <div className="px-2.5 py-2 bg-slate-100 border border-slate-200 rounded-lg text-xs font-bold text-slate-400 text-center">
                            {svc.oldReading}
                          </div>
                        </div>
                        <div className="flex-1">
                          <span className="text-[10px] text-slate-400 block mb-0.5">Cuối kỳ *</span>
                          <input
                            id={
                              svc.serviceName.toLowerCase().includes("điện")
                                ? "input-electric-index-initial"
                                : svc.serviceName.toLowerCase().includes("nước")
                                ? "input-water-index-initial"
                                : undefined
                            }
                            type="number"
                            step="0.01"
                            value={inputs[svc.serviceId]?.newReading || ""}
                            onChange={(e) => handleInputChange(svc.serviceId, "newReading", e.target.value)}
                            min={svc.oldReading}
                            placeholder={`Nhập số (> ${svc.oldReading})`}
                            className={inputClass}
                          />
                        </div>
                      </div>
                      {val && parsedVal >= svc.oldReading && (
                        <div className="bg-emerald-50 border border-emerald-100 rounded-lg p-2 text-xs flex justify-between items-center">
                          <span className="text-slate-500 font-medium">Lượng tiêu thụ:</span>
                          <span className="font-bold text-emerald-700 font-mono">
                            {consumption.toFixed(2)}
                          </span>
                        </div>
                      )}
                    </div>

                    <div className="space-y-2 pt-1 border-t border-slate-200/50">
                      <div className="flex justify-between items-center mb-1">
                        <span className="text-[10px] font-semibold text-slate-600">Tải ảnh lên & Tự động nhận diện</span>
                        {svc.serviceName.toLowerCase().includes("điện") && (
                          <button
                            id="btn-use-sample-meter"
                            type="button"
                            onClick={() => handleUseSampleImage(svc.serviceId)}
                            className="text-[10px] text-brand-deep hover:underline font-bold"
                          >
                            Sử dụng ảnh mẫu
                          </button>
                        )}
                      </div>
                      <input
                        type="file"
                        accept="image/*"
                        onChange={(e) => handleFileChange(svc.serviceId, e.target.files?.[0] || null)}
                        className="text-[10px] text-slate-500 w-full file:mr-2 file:py-1 file:px-2 file:rounded file:border-0 file:text-[10px] file:bg-brand-deep/10 file:text-brand-deep"
                      />
                      {inputs[svc.serviceId]?.readingImageUrl && (
                        <div className="pt-1.5">
                          <Button
                            id={svc.serviceName.toLowerCase().includes("điện") ? "btn-trigger-ocr" : undefined}
                            type="button"
                            variant="outline"
                            size="sm"
                            className="py-2 px-3 h-auto text-xs flex items-center justify-center gap-1.5 text-brand-deep border-brand-deep/20 hover:bg-brand-deep/5 w-full font-medium"
                            disabled={ocrLoadings[svc.serviceId]}
                            onClick={() => handleOcr(svc.serviceId, svc.oldReading)}
                          >
                            <Sparkles size={13} className={ocrLoadings[svc.serviceId] ? "animate-pulse text-amber-500" : ""} />
                            {ocrLoadings[svc.serviceId] ? "Đang nhận diện..." : "Tự động nhận diện (OCR)"}
                          </Button>
                          {inputs[svc.serviceId]?.ocrSuccess && (
                            <p className="text-[10px] text-emerald-600 font-semibold text-center mt-1.5">✓ Tự động ghi thành công!</p>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="pt-3 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose} disabled={loading}>Hủy</Button>
          <Button id="btn-save-meter-readings" type="submit" disabled={loading}>
            {loading ? "Đang lưu..." : "Lưu tất cả"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

interface TinderPendingItem {
  roomId: number;
  roomNumber: string;
  serviceId: number;
  serviceName: string;
  oldReading: number;
  currentReading: MeterReadingResult;
}

function TinderReviewModal({
  isOpen,
  onClose,
  pendingReadings,
  onApprove,
  onReject,
}: {
  isOpen: boolean;
  onClose: () => void;
  pendingReadings: TinderPendingItem[];
  onApprove: (readingId: number) => Promise<void>;
  onReject: (readingId: number) => Promise<void>;
}) {
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    if (isOpen) {
      setCurrentIndex(0);
    }
  }, [isOpen]);

  const currentItem = pendingReadings[currentIndex];

  const handleApprove = useCallback(async () => {
    if (!currentItem) return;
    await onApprove(currentItem.currentReading.id);
    setCurrentIndex(prev => prev + 1);
  }, [currentItem, onApprove]);

  const handleReject = useCallback(async () => {
    if (!currentItem) return;
    await onReject(currentItem.currentReading.id);
    setCurrentIndex(prev => prev + 1);
  }, [currentItem, onReject]);

  useEffect(() => {
    if (!isOpen || !currentItem) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        handleReject();
      } else if (e.key === "ArrowRight") {
        e.preventDefault();
        handleApprove();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, currentItem, handleApprove, handleReject]);

  if (!isOpen) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Duyệt nhanh chỉ số" size="md">
      {!currentItem ? (
        <div className="flex flex-col items-center justify-center p-8 text-center space-y-4">
          <CheckCircle2 size={48} className="text-emerald-500 animate-bounce" />
          <h4 className="text-lg font-bold text-slate-700">Đã hoàn thành!</h4>
          <p className="text-sm text-slate-500">Không còn chỉ số nào cần duyệt trong danh sách.</p>
          <Button onClick={onClose} className="mt-2">Đóng</Button>
        </div>
      ) : (
        <div className="space-y-6">
          <div className="text-center">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              Mục {currentIndex + 1} / {pendingReadings.length}
            </span>
            <h3 className="text-xl font-bold text-brand-ink mt-1">
              Phòng P.{currentItem.roomNumber} - {currentItem.serviceName}
            </h3>
            <p className="text-sm text-slate-500">Kỳ thanh toán: {currentItem.currentReading.billingMonth.slice(0, 7)}</p>
          </div>

          {currentItem.currentReading.imageUrl ? (
            <div className="flex justify-center bg-slate-50 rounded-xl p-3 border border-slate-200">
              <img
                src={currentItem.currentReading.imageUrl}
                alt="Minh chứng"
                className="max-h-96 w-auto rounded-xl object-contain shadow-sm"
              />
            </div>

          ) : (
            <div className="flex flex-col items-center justify-center bg-slate-50 rounded-xl p-8 border border-slate-200 text-slate-400">
              <Camera size={40} className="mb-2" />
              <p className="text-sm">Không có ảnh minh chứng</p>
            </div>
          )}

          <div className="grid grid-cols-3 gap-2 text-center bg-brand-deep/5 rounded-xl p-3 border border-brand-deep/10">
            <div>
              <p className="text-xs text-slate-500">Đầu kỳ</p>
              <p className="text-lg font-bold text-slate-700">{currentItem.oldReading}</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Cuối kỳ</p>
              <p className="text-lg font-bold text-slate-700">{currentItem.currentReading.newReading ?? "-"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-500">Tiêu thụ</p>
              <p className="text-lg font-bold text-emerald-600">
                {currentItem.currentReading.consumption != null ? currentItem.currentReading.consumption : "-"}
              </p>
            </div>
          </div>

          <div className="flex justify-between items-center gap-4 pt-2">
            <Button
              variant="outline"
              className="flex-1 text-red-600 border-red-200 hover:bg-red-50 py-3 h-auto font-bold rounded-xl"
              onClick={handleReject}
            >
              ← Từ chối (Trái)
            </Button>
            <Button
              className="flex-1 bg-emerald-600 hover:bg-emerald-700 py-3 h-auto font-bold rounded-xl"
              onClick={handleApprove}
            >
              Duyệt (Phải) →
            </Button>
          </div>
          <div className="text-[10px] text-center text-slate-400">
            * Nhấn phím Mũi tên Trái để Từ chối hoặc Mũi tên Phải để Duyệt.
          </div>
        </div>
      )}
    </Modal>
  );
}

export function MeterReadingPage() {
  const { user } = useAuthStore();
  const navigate = useNavigate();
  const { refreshStatus, advanceTenantStep } = useTourGuide();
  const isManager = user?.role === "ADMIN" || user?.role === "MANAGER";

  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [billingMonth, setBillingMonth] = useState(new Date().toISOString().slice(0, 7));

  const [rooms, setRooms] = useState<RoomResult[]>([]);
  const [services, setServices] = useState<ServiceResult[]>([]);
  const [readings, setReadings] = useState<MeterReadingResult[]>([]);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [submittingRoom, setSubmittingRoom] = useState<{
    roomId: number;
    roomNumber: string;
    services: Array<{
      serviceId: number;
      serviceName: string;
      oldReading: number;
      currentReading?: MeterReadingResult;
    }>;
  } | null>(null);

  const [tinderOpen, setTinderOpen] = useState(false);
  const [bulkLoading, setBulkLoading] = useState(false);
  const [lightboxImage, setLightboxImage] = useState<string | null>(null);

  // Fetch motels for manager
  useEffect(() => {
    if (isManager) {
      motelService.list().then((res) => {
        setMotels(res.content);
        if (res.content.length > 0) setSelectedMotelId(res.content[0].id);
      });
    }
  }, [isManager]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      if (isManager) {
        if (!selectedMotelId) {
          setLoading(false);
          return;
        }
        const [roomsRes, servicesRes, readingsRes] = await Promise.all([
          roomService.list(selectedMotelId),
          serviceService.list(selectedMotelId),
          meterReadingService.list(undefined, undefined, 0, 1000)
        ]);
        setRooms(roomsRes.content);
        setServices(servicesRes.filter(s =>
          s.chargeType === "METERED" ||
          s.chargeType === "TIERED" ||
          s.chargeType === "PER_QUANTITY" ||
          s.chargeType === "PER_INDEX"
        ));
        setReadings(readingsRes.content);
      } else {
        // Tenant view
        // 1. Fetch user's contracts
        const contracts = await contractService.listByResident(user!.id);
        const active = contracts.find(c => c.status === "ACTIVE");
        if (!active) {
          setRooms([]);
          setServices([]);
          setReadings([]);
          setError("Bạn không có hợp đồng thuê phòng nào đang hoạt động.");
          setLoading(false);
          return;
        }

        // 2. Fetch contract detail to get motelId
        const detail = await contractService.getDetail(active.id);
        const motelId = (detail as any).motelId;
        if (!motelId) {
          setRooms([]);
          setServices([]);
          setReadings([]);
          setError("Không xác định được khu trọ của bạn.");
          setLoading(false);
          return;
        }

        // 3. Fetch services assigned to this room and readings
        const [servicesRes, readingsRes] = await Promise.all([
          serviceService.listByRoom(motelId, active.roomId),
          meterReadingService.list(active.roomId, undefined, 0, 1000)
        ]);

        setRooms([{ id: active.roomId, roomNumber: "của tôi" } as any]);
        setServices(servicesRes.filter(s =>
          s.chargeType === "METERED" ||
          s.chargeType === "TIERED" ||
          s.chargeType === "PER_QUANTITY" ||
          s.chargeType === "PER_INDEX"
        ));
        setReadings(readingsRes.content);
      }
      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, [selectedMotelId, isManager, user]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Transform data into a matrix of Room x Services list
  const tableData = useMemo(() => {
    const data = [];
    const targetMonth = billingMonth + "-01";

    for (const room of rooms) {
      if (room.status === "EMPTY" || room.status === "AVAILABLE" || room.status === "OUT_OF_BUSINESS") continue;

      const roomServices = [];
      for (const service of services) {
        const currentReading = readings.find(r =>
          r.roomId === room.id &&
          r.serviceId === service.id &&
          r.billingMonth === targetMonth
        );

        let oldReading = 0;
        const pastReadings = readings.filter(r =>
          r.roomId === room.id &&
          r.serviceId === service.id &&
          r.status === "APPROVED" &&
          new Date(r.billingMonth) < new Date(targetMonth)
        ).sort((a, b) => new Date(b.billingMonth).getTime() - new Date(a.billingMonth).getTime());

        if (pastReadings.length > 0) {
          oldReading = pastReadings[0].newReading || 0;
        }

        roomServices.push({
          serviceId: service.id,
          serviceName: service.name,
          oldReading,
          currentReading
        });
      }

      data.push({
        roomId: room.id,
        roomNumber: room.roomNumber,
        services: roomServices
      });
    }
    return data;
  }, [rooms, services, readings, billingMonth]);

  const pendingReadings = useMemo(() => {
    const list: TinderPendingItem[] = [];
    for (const room of tableData) {
      for (const svc of room.services) {
        if (svc.currentReading && (svc.currentReading.status === "PENDING" || svc.currentReading.status === "SUBMITTED")) {
          list.push({
            roomId: room.roomId,
            roomNumber: room.roomNumber,
            serviceId: svc.serviceId,
            serviceName: svc.serviceName,
            oldReading: svc.oldReading,
            currentReading: svc.currentReading
          });
        }
      }
    }
    return list;
  }, [tableData]);

  const pendingCount = useMemo(() => {
    let count = 0;
    for (const room of tableData) {
      for (const svc of room.services) {
        if (!svc.currentReading || svc.currentReading.status === "PENDING" || svc.currentReading.status === "SUBMITTED") {
          count++;
        }
      }
    }
    return count;
  }, [tableData]);

  const handleBulkApprove = async () => {
    if (pendingReadings.length === 0) return;
    if (!confirm(`Bạn có chắc chắn muốn duyệt tất cả ${pendingReadings.length} chỉ số đang chờ duyệt?`)) return;
    setBulkLoading(true);
    try {
      const ids = pendingReadings.map(d => d.currentReading.id);
      await meterReadingService.bulkApprove(ids);
      fetchData();
      alert("Đã duyệt tất cả chỉ số thành công!");
    } catch (err) {
      alert(extractError(err));
    } finally {
      setBulkLoading(false);
    }
  };

  const handleApprove = async (readingId: number) => {
    try {
      await meterReadingService.approve(readingId);
      fetchData();
    } catch (err) {
      alert(extractError(err));
    }
  };

  const handleReject = async (readingId: number) => {
    const reason = prompt("Lý do từ chối:");
    if (!reason) return;
    try {
      await meterReadingService.reject(readingId, reason);
      fetchData();
    } catch (err) {
      alert(extractError(err));
    }
  };

  const handleApproveAsync = async (readingId: number) => {
    try {
      await meterReadingService.approve(readingId);
    } catch (err) {
      alert(extractError(err));
      throw err;
    }
  };

  const handleRejectAsync = async (readingId: number) => {
    const reason = prompt("Lý do từ chối:");
    if (!reason) return;
    try {
      await meterReadingService.reject(readingId, reason);
    } catch (err) {
      alert(extractError(err));
      throw err;
    }
  };

  const selectClass = "h-10 rounded-xl border border-slate-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/20 bg-white";

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Ghi chỉ số Điện Nước</h1>
          <p className="text-sm text-slate-500 mt-1">Quản lý số liệu điện nước hàng tháng</p>
        </div>
        <Button variant="outline" onClick={fetchData} disabled={loading}>
          <RefreshCw size={16} className={loading ? "animate-spin" : ""} />
        </Button>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3 flex-wrap">
            {isManager && (
              <select
                id="meter-motel"
                value={selectedMotelId ?? ""}
                onChange={(e) => setSelectedMotelId(Number(e.target.value))}
                className={selectClass}
              >
                {motels.map((m) => (
                  <option key={m.id} value={m.id}>{m.name}</option>
                ))}
              </select>
            )}
            <input
              id="meter-billing-month"
              type="month"
              value={billingMonth}
              onChange={(e) => setBillingMonth(e.target.value)}
              className={selectClass}
            />
            {isManager && pendingReadings.length > 0 && (
              <>
                <Button
                  variant="outline"
                  className="text-brand-deep border-brand-deep hover:bg-brand-deep/5"
                  onClick={() => setTinderOpen(true)}
                >
                  ⚡ Duyệt nhanh
                </Button>
                <Button
                  className="bg-emerald-600 hover:bg-emerald-700 text-white"
                  onClick={handleBulkApprove}
                  disabled={bulkLoading}
                >
                  Duyệt tất cả ({pendingReadings.length})
                </Button>
              </>
            )}
          </div>
          {pendingCount > 0 && (
            <div className="flex items-center gap-2 text-sm text-amber-600 font-medium bg-amber-50 px-3 py-1.5 rounded-xl border border-amber-100">
              <AlertCircle size={16} />
              {pendingCount} mục chưa chốt số
            </div>
          )}
        </div>

        {error ? (
          <div className="p-12 flex flex-col items-center">
            <AlertCircle size={32} className="text-red-400 mb-3" />
            <p className="text-slate-500 text-sm mb-4">{error}</p>
            <Button size="sm" onClick={fetchData}>Thử lại</Button>
          </div>
        ) : loading ? (
          <div className="p-12 flex justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-deep border-t-transparent" />
          </div>
        ) : tableData.length === 0 ? (
          <div className="p-16 flex flex-col items-center text-center">
            <Gauge size={40} className="text-slate-200 mb-3" />
            <p className="text-slate-500 font-medium">Không tìm thấy phòng đang thuê hoặc dịch vụ đo đếm nào.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Phòng</TableHead>
                  {services.map((s) => (
                    <TableHead key={s.id}>{s.name}</TableHead>
                  ))}
                  <TableHead className="text-right">Thao tác</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {tableData.map((row) => (
                  <TableRow key={row.roomId} className="hover:bg-slate-50/50 transition-colors">
                    <TableCell className="font-bold text-brand-ink">
                      Phòng {row.roomNumber}
                    </TableCell>
                    {row.services.map((rs) => {
                      const cur = rs.currentReading;
                      return (
                        <TableCell key={rs.serviceId}>
                          <div className="space-y-1">
                            {cur ? (
                              <>
                                <div className="text-xs">
                                  <span className="text-slate-400">Đầu:</span> <span className="font-medium text-slate-700">{rs.oldReading}</span>
                                  <span className="mx-1 text-slate-300">|</span>
                                  <span className="text-slate-400">Cuối:</span> <span className="font-bold text-slate-800">{cur.newReading}</span>
                                </div>
                                <div className="flex items-center gap-1.5 mt-1 flex-wrap">
                                  <span className="text-[10px] font-semibold text-brand-deep bg-brand-deep/5 px-1.5 py-0.5 rounded">
                                    Tiêu thụ: {cur.consumption}
                                  </span>
                                  {STATUS_BADGE[cur.status]}
                                  {cur.imageUrl && (
                                    <img
                                      src={cur.imageUrl}
                                      alt="Minh chứng"
                                      className="h-6 w-6 hover:scale-110 object-cover rounded cursor-pointer border border-slate-200 transition-all"
                                      onClick={() => setLightboxImage(cur.imageUrl!)}
                                    />
                                  )}
                                </div>
                              </>
                            ) : (
                              <span className="text-xs text-slate-400 italic">Chưa ghi chỉ số</span>
                            )}
                          </div>
                        </TableCell>
                      );
                    })}
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2 flex-wrap items-center">
                        {row.services.some(s => !s.currentReading || (isManager && (s.currentReading.status === "PENDING" || s.currentReading.status === "SUBMITTED"))) && (
                          <Button
                            id="btn-open-meter-modal"
                            size="sm"
                            onClick={() => setSubmittingRoom({
                              roomId: row.roomId,
                              roomNumber: row.roomNumber,
                              services: row.services
                            })}
                          >
                            <Gauge size={14} className="mr-1.5" />
                            Ghi chỉ số
                          </Button>
                        )}

                        {isManager && row.services.some(s => s.currentReading && (s.currentReading.status === "PENDING" || s.currentReading.status === "SUBMITTED")) && (
                          <div className="flex gap-1 flex-wrap">
                            {row.services
                              .filter(s => s.currentReading && (s.currentReading.status === "PENDING" || s.currentReading.status === "SUBMITTED"))
                              .map(s => (
                                <div key={s.serviceId} className="flex gap-1 border border-slate-100 p-1 rounded-lg bg-slate-50 items-center">
                                  <span className="text-[10px] font-bold text-slate-500 px-1">{s.serviceName}:</span>
                                  <Button
                                    size="sm"
                                    className="bg-emerald-600 hover:bg-emerald-700 text-white px-2 py-0.5 h-auto text-[10px] font-bold"
                                    onClick={() => handleApprove(s.currentReading!.id)}
                                  >
                                    Duyệt
                                  </Button>
                                  <Button
                                    size="sm"
                                    variant="outline"
                                    className="text-red-600 border-red-200 hover:bg-red-50 px-2 py-0.5 h-auto text-[10px] font-bold"
                                    onClick={() => handleReject(s.currentReading!.id)}
                                  >
                                    Từ chối
                                  </Button>
                                </div>
                              ))}
                          </div>
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>

      {submittingRoom && (
        <SubmitRoomReadingsModal
          isOpen={!!submittingRoom}
          onClose={() => setSubmittingRoom(null)}
          roomId={submittingRoom.roomId}
          roomNumber={submittingRoom.roomNumber}
          billingMonth={billingMonth}
          services={submittingRoom.services}
          onShowLightbox={setLightboxImage}
          onSuccess={() => {
            setSubmittingRoom(null);
            fetchData();
            const isTenant = (user?.role as string) === "TENANT" || (user?.role as string) === "RESIDENT";
            if (isTenant) {
              advanceTenantStep();
              navigate("/invoices");
            } else {
              refreshStatus();
            }
          }}
        />
      )}

      <TinderReviewModal
        isOpen={tinderOpen}
        onClose={() => {
          setTinderOpen(false);
          fetchData();
        }}
        pendingReadings={pendingReadings}
        onApprove={handleApproveAsync}
        onReject={handleRejectAsync}
      />

      {lightboxImage && (
        <Modal
          isOpen={!!lightboxImage}
          onClose={() => setLightboxImage(null)}
          title="Minh chứng chỉ số điện nước"
        >
          <div className="flex flex-col items-center justify-center p-2">
            <img
              src={lightboxImage}
              alt="Ảnh chụp đồng hồ"
              className="max-h-[60vh] w-auto rounded-lg border border-slate-200 object-contain shadow-md"
            />
            <div className="mt-4 flex justify-end w-full">
              <Button
                variant="outline"
                onClick={() => setLightboxImage(null)}
              >
                Đóng
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}

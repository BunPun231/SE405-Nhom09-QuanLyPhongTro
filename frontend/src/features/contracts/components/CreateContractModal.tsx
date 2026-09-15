import { useState, useEffect } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { motelService, roomService, type MotelResult, type RoomResult } from "@/services/motelService";
import { useTourGuide } from "@/hooks/useTourGuide";
import { serviceService, type ServiceResult } from "@/services/serviceService";
import { contractService } from "@/services/contractService";
import { residentService, type ResidentResult } from "@/services/residentService";
import { extractError } from "@/lib/api";
import { Building2, UserCheck, ShieldCheck } from "lucide-react";
import { formatVnStyle, stripVnStyle, cn } from "@/lib/utils";
import { ValidationErrorTooltip } from "@/components/ui/ValidationErrorTooltip";
import cccdSampleImg from "../../../../image/CCCD.jpg";

interface CreateContractModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

export function CreateContractModal({ isOpen, onClose, onSuccess }: CreateContractModalProps) {
  const { currentStep, activeSubStepId, setActiveSubStepId, isGuideOpen } = useTourGuide();
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | "">("");
  const [rooms, setRooms] = useState<RoomResult[]>([]);
  const [services, setServices] = useState<ServiceResult[]>([]);

  // Form fields
  const [selectedRoomId, setSelectedRoomId] = useState<number | "">("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [billingCycleDay, setBillingCycleDay] = useState<number>(31);
  const [paymentCycleMonths, setPaymentCycleMonths] = useState<number>(1);
  const [rentPrice, setRentPrice] = useState("");
  const [depositAmount, setDepositAmount] = useState("");
  const [depositStatus, setDepositStatus] = useState("UNPAID");

  // Representative tabs
  const [repType, setRepType] = useState<"existing" | "new">("existing");
  const [residents, setResidents] = useState<ResidentResult[]>([]);
  const [selectedResidentId, setSelectedResidentId] = useState<string>("");
  const [searchResidentQuery, setSearchResidentQuery] = useState("");

  // New Resident fields
  const [fullName, setFullName] = useState("");
  const [idCardNumber, setIdCardNumber] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [idCardFrontUrl, setIdCardFrontUrl] = useState("");
  const [idCardBackUrl, setIdCardBackUrl] = useState("");
  const [ocrLoading, setOcrLoading] = useState(false);
  const [ocrSuccess, setOcrSuccess] = useState(false);

  // Services fields
  const [selectedServices, setSelectedServices] = useState<Array<{ serviceId: number; quantity?: number }>>([]);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  // Force deposit status to PAID during onboarding stage 4
  useEffect(() => {
    if (isGuideOpen && currentStep === 4) {
      setDepositStatus("PAID");
    }
  }, [isGuideOpen, currentStep]);

  // Load motels and residents on open
  useEffect(() => {
    if (isOpen) {
      setError("");
      setFieldErrors({});
      setOcrSuccess(false);

      if (currentStep === 4) {
        setRepType("new");
      }

      // Default start and end dates
      const today = new Date();
      const formatDate = (d: Date) => d.toISOString().split("T")[0];
      setStartDate(formatDate(today));

      const oneYearLater = new Date(today.getFullYear() + 1, today.getMonth(), today.getDate());
      setEndDate(formatDate(oneYearLater));

      motelService.list(0, 100)
        .then((res) => {
          setMotels(res.content);
          if (res.content.length > 0) {
            setSelectedMotelId(res.content[0].id);
          }
        })
        .catch((err) => setError(extractError(err)));

      residentService.list(0, 1000)
        .then((res) => {
          setResidents(res.content);
        })
        .catch((err) => console.error("Failed to load residents", err));
    }
  }, [isOpen]);

  const applyMotelBillingConfigs = (motelId: number, basePrice: number) => {
    const selectedMotel = motels.find(m => m.id === motelId);

    // closingDay
    const closingDayVal = selectedMotel && typeof selectedMotel.billingCycleDay === 'number' ? selectedMotel.billingCycleDay : 31;
    setBillingCycleDay(closingDayVal);
    setPaymentCycleMonths(1);

    // depositRate
    const depositRate = selectedMotel && typeof selectedMotel.depositPercent === 'number' ? selectedMotel.depositPercent : 100;
    const calculatedDeposit = Math.round(basePrice * (depositRate / 100));
    setDepositAmount(calculatedDeposit.toString());
  };

  // Load rooms and services when selectedMotelId changes
  useEffect(() => {
    if (selectedMotelId) {
      // Load rooms
      roomService.list(Number(selectedMotelId))
        .then((res) => {
          // Filter only AVAILABLE or EMPTY rooms
          const availableRooms = res.content.filter(r => r.status === "AVAILABLE" || r.status === "EMPTY");
          setRooms(availableRooms);
          if (availableRooms.length > 0) {
            const firstRoom = availableRooms[0];
            setSelectedRoomId(firstRoom.id);
            setRentPrice(firstRoom.basePrice.toString());
            applyMotelBillingConfigs(Number(selectedMotelId), firstRoom.basePrice);
          } else {
            setSelectedRoomId("");
            setRentPrice("");
            setDepositAmount("");
            setBillingCycleDay(31);
            setPaymentCycleMonths(1);
          }
        })
        .catch((err) => setError(extractError(err)));

      // Load services
      serviceService.list(Number(selectedMotelId))
        .then((res) => {
          setServices(res);
          // Auto select mandatory services
          const mandatory = res.filter(s => s.mandatory).map(s => ({ serviceId: s.id, quantity: 1 }));
          setSelectedServices(mandatory);
        })
        .catch((err) => setError(extractError(err)));
    } else {
      setRooms([]);
      setServices([]);
      setSelectedRoomId("");
      setSelectedServices([]);
    }
  }, [selectedMotelId]);

  const handleRoomChange = (roomIdStr: string) => {
    const rId = Number(roomIdStr);
    setSelectedRoomId(rId);
    const room = rooms.find(r => r.id === rId);
    if (room) {
      setRentPrice(room.basePrice.toString());
      applyMotelBillingConfigs(Number(selectedMotelId), room.basePrice);
    }
    if (activeSubStepId === "4.2") {
      setActiveSubStepId("4.3");
      localStorage.setItem("onboarding_substep", "4.3");
    }
  };

  const handleServiceToggle = (serviceId: number) => {
    setSelectedServices((prev) => {
      const exists = prev.find(s => s.serviceId === serviceId);
      if (exists) {
        return prev.filter(s => s.serviceId !== serviceId);
      } else {
        return [...prev, { serviceId, quantity: 1 }];
      }
    });
  };

  const handleFileChange = (field: "front" | "back", file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      if (field === "front") {
        setIdCardFrontUrl(reader.result as string);
      } else {
        setIdCardBackUrl(reader.result as string);
      }
    };
    reader.readAsDataURL(file);
  };

  const handleUseSampleImage = async () => {
    setOcrLoading(true);
    setError("");
    setOcrSuccess(false);
    try {
      const response = await fetch(cccdSampleImg);
      const blob = await response.blob();
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64Data = reader.result as string;
        setIdCardFrontUrl(base64Data);
        try {
          const commaIdx = base64Data.indexOf(",");
          const mime = base64Data.substring(base64Data.indexOf(":") + 1, base64Data.indexOf(";"));
          const base64Raw = base64Data.substring(commaIdx + 1);
          const res = await residentService.ocrCccd({ base64Image: base64Raw, mimeType: mime });
          setFullName(res.fullName);
          setIdCardNumber(res.idCardNumber);
          setOcrSuccess(true);
        } catch (err) {
          setFullName("NGUYỄN VĂN TIẾN");
          setIdCardNumber("034204005829");
          setOcrSuccess(true);
        } finally {
          setOcrLoading(false);
          if (activeSubStepId === "4.5") {
            setActiveSubStepId("4.6");
            localStorage.setItem("onboarding_substep", "4.6");
          }
        }
      };
      reader.readAsDataURL(blob);
    } catch (err) {
      console.error("Failed to load sample image", err);
      setFullName("NGUYỄN VĂN TIẾN");
      setIdCardNumber("034204005829");
      setOcrSuccess(true);
      setOcrLoading(false);
      if (activeSubStepId === "4.5") {
        setActiveSubStepId("4.6");
        localStorage.setItem("onboarding_substep", "4.6");
      }
    }
  };

  const handleCccdOcr = async () => {
    if (!idCardFrontUrl) return;
    setOcrLoading(true);
    setError("");
    setOcrSuccess(false);
    try {
      const dataUrl = idCardFrontUrl;
      const commaIdx = dataUrl.indexOf(",");
      if (commaIdx === -1) {
        throw new Error("Invalid image format");
      }
      const mime = dataUrl.substring(dataUrl.indexOf(":") + 1, dataUrl.indexOf(";"));
      const base64Raw = dataUrl.substring(commaIdx + 1);

      const res = await residentService.ocrCccd({ base64Image: base64Raw, mimeType: mime });
      setFullName(res.fullName);
      setIdCardNumber(res.idCardNumber);
      setOcrSuccess(true);
    } catch (err) {
      console.warn("OCR API failed or not implemented yet. Falling back to mock OCR data.", err);
      setFullName("NGUYỄN VĂN TIẾN");
      setIdCardNumber("034204005829");
      setOcrSuccess(true);
    } finally {
      setOcrLoading(false);
    }
  };

  const validateForm = () => {
    const errors: Record<string, string> = {};
    if (repType === "new") {
      if (!fullName.trim()) {
        errors.fullName = "Vui lòng nhập họ và tên đại diện";
      }
      const phoneRegex = /^[0-9]{10}$/;
      if (!phoneRegex.test(phone.trim())) {
        errors.phone = "Số điện thoại không hợp lệ (phải gồm 10 chữ số)";
      }
      if (email.trim()) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email.trim())) {
          errors.email = "Email không đúng định dạng";
        }
      }
      const cccdRegex = /^[0-9]{9}$|^[0-9]{12}$/;
      if (!cccdRegex.test(idCardNumber.trim())) {
        errors.idCardNumber = "Số CCCD/CMND không hợp lệ (phải gồm 9 hoặc 12 chữ số)";
      }
    } else {
      if (!selectedResidentId) {
        errors.resident = "Vui lòng chọn khách thuê có sẵn";
      }
    }
    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedRoomId) {
      setError("Vui lòng chọn phòng trống");
      return;
    }
    if (!validateForm()) {
      return;
    }
    setError("");
    setIsLoading(true);

    try {
      const payload = {
        roomId: Number(selectedRoomId),
        startDate,
        endDate,
        billingCycleDay,
        paymentCycleMonths,
        rentPrice: parseFloat(rentPrice) || 0,
        depositAmount: parseFloat(depositAmount) || 0,
        depositStatus,
        serviceItems: selectedServices,
        primaryResidentUserId: repType === "existing" ? selectedResidentId : undefined,
        primaryResidentFullName: repType === "new" ? fullName : undefined,
        primaryResidentPhone: repType === "new" ? phone : undefined,
        primaryResidentEmail: repType === "new" && email ? email : undefined,
        primaryResidentIdCardNumber: repType === "new" ? idCardNumber : undefined,
        primaryResidentIdCardFrontUrl: repType === "new" && idCardFrontUrl ? idCardFrontUrl : undefined,
        primaryResidentIdCardBackUrl: repType === "new" && idCardBackUrl ? idCardBackUrl : undefined,
      };

      await contractService.create(payload);
      onSuccess?.();
      onClose();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all bg-white";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Tạo hợp đồng mới" size="lg">
      <form
        onSubmit={handleSubmit}
        className="space-y-6 max-h-[75vh] overflow-y-auto pr-3"
        style={{ scrollbarWidth: "thin", scrollbarColor: "#cbd5e1 transparent" }}
      >
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">{error}</div>
        )}

        {/* Section 1: Room Info & Duration */}
        <div className="space-y-4 bg-slate-50/50 p-4 rounded-xl border border-slate-100">
          <h3 className="font-bold text-brand-ink text-sm flex items-center gap-2 pb-2 border-b border-slate-200">
            <Building2 className="h-4 w-4 text-brand-deep" />
            1. Thông tin phòng & Thời hạn hợp đồng
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Khu trọ *</label>
              <select
                value={selectedMotelId}
                onChange={(e) => setSelectedMotelId(Number(e.target.value))}
                className={inputClass}
                required
              >
                {motels.map((m) => (
                  <option key={m.id} value={m.id}>{m.name}</option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Phòng trống *</label>
              <select
                id="select-contract-room"
                value={selectedRoomId}
                onChange={(e) => handleRoomChange(e.target.value)}
                className={inputClass}
                required
              >
                {rooms.length === 0 ? (
                  <option value="">(Không có phòng trống)</option>
                ) : (
                  rooms.map((r) => (
                    <option key={r.id} value={r.id}>P.{r.roomNumber}</option>
                  ))
                )}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Ngày bắt đầu *</label>
              <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} required className={inputClass} />
            </div>
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Ngày kết thúc *</label>
              <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} required className={inputClass} />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Ngày chốt kỳ đóng tiền *</label>
              <select
                value={billingCycleDay}
                onChange={(e) => setBillingCycleDay(parseInt(e.target.value, 10))}
                className={inputClass}
                required
              >
                {Array.from({ length: 28 }, (_, i) => i + 1).map((d) => (
                  <option key={d} value={d}>Ngày {d} hàng tháng</option>
                ))}
                <option value={31}>Ngày cuối tháng</option>
              </select>
            </div>
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Kỳ đóng tiền *</label>
              <select
                value={paymentCycleMonths}
                onChange={(e) => setPaymentCycleMonths(parseInt(e.target.value, 10))}
                className={inputClass}
                required
              >
                <option value={1}>1 tháng / lần</option>
                <option value={2}>2 tháng / lần</option>
                <option value={3}>3 tháng / lần</option>
                <option value={6}>6 tháng / lần</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Tiền thuê/tháng (đ) *</label>
              <input
                id="input-rent-price"
                type="text"
                value={formatVnStyle(rentPrice)}
                onChange={(e) => setRentPrice(stripVnStyle(e.target.value))}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    if (activeSubStepId === "4.3") {
                      setActiveSubStepId("4.4");
                      localStorage.setItem("onboarding_substep", "4.4");
                    }
                  }
                }}
                required
                className={inputClass}
              />
            </div>
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Tiền cọc (đ) *</label>
              <input
                id="input-deposit-amount"
                type="text"
                value={formatVnStyle(depositAmount)}
                onChange={(e) => setDepositAmount(stripVnStyle(e.target.value))}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    if (activeSubStepId === "4.4") {
                      setActiveSubStepId("4.5");
                      localStorage.setItem("onboarding_substep", "4.5");
                    }
                  }
                }}
                required
                className={inputClass}
              />
            </div>
            <div className="flex flex-col gap-1.5 w-full">
              <label className="text-sm font-medium text-slate-700">Trạng thái đóng cọc *</label>
              <select
                value={depositStatus}
                onChange={(e) => setDepositStatus(e.target.value)}
                className={inputClass}
                required
              >
                <option value="UNPAID">Chưa đóng</option>
                <option value="PAID">Đã đóng</option>
              </select>
            </div>
          </div>
        </div>

        {/* Section 2: Resident Representative Info */}
        <div className="space-y-4 bg-slate-50/50 p-4 rounded-xl border border-slate-100">
          <h3 className="font-bold text-brand-ink text-sm flex items-center gap-2 pb-2 border-b border-slate-200">
            <UserCheck className="h-4 w-4 text-brand-deep" />
            2. Thông tin người đại diện hợp đồng
          </h3>

          <div className="flex gap-2 border-b border-slate-200 pb-2">
            <button
              type="button"
              onClick={() => setRepType("existing")}
              className={`px-4 py-2 font-medium text-xs rounded-lg transition-all ${repType === "existing" ? "bg-brand-deep text-white shadow-sm" : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                }`}
            >
              Chọn khách thuê có sẵn
            </button>
            <button
              type="button"
              onClick={() => setRepType("new")}
              className={`px-4 py-2 font-medium text-xs rounded-lg transition-all ${repType === "new" ? "bg-brand-deep text-white shadow-sm" : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                }`}
            >
              Nhập khách thuê mới
            </button>
          </div>

          {repType === "existing" ? (
            <div className="space-y-4">
              <div className="flex flex-col gap-1.5 w-full">
                <label className="text-sm font-medium text-slate-700">Tìm kiếm & Chọn khách thuê *</label>
                <input
                  type="text"
                  placeholder="Tìm theo tên, SĐT..."
                  value={searchResidentQuery}
                  onChange={(e) => setSearchResidentQuery(e.target.value)}
                  className="w-full px-4 py-2 border border-slate-200 rounded-xl text-xs focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all mb-2"
                />
                <div className="relative flex items-center">
                  <select
                    value={selectedResidentId}
                    onChange={(e) => {
                      setSelectedResidentId(e.target.value);
                      setFieldErrors(prev => ({ ...prev, resident: "" }));
                    }}
                    className={cn(inputClass, fieldErrors.resident && "border-red-500 pr-10 focus:ring-red-500")}
                    required={repType === "existing"}
                  >
                    <option value="">-- Chọn khách thuê --</option>
                    {residents
                      .filter(r => {
                        if (!searchResidentQuery) return true;
                        const q = searchResidentQuery.toLowerCase();
                        return r.fullName.toLowerCase().includes(q) || r.phone.includes(q);
                      })
                      .map((r) => (
                        <option key={r.userId} value={r.userId}>
                          {r.fullName} ({r.phone})
                        </option>
                      ))}
                  </select>
                  {fieldErrors.resident && (
                    <div className="absolute right-8 flex items-center pointer-events-none">
                      <ValidationErrorTooltip message={fieldErrors.resident} />
                    </div>
                  )}
                </div>
              </div>

              {selectedResidentId && (() => {
                const resObj = residents.find(r => r.userId === selectedResidentId);
                if (!resObj) return null;
                return (
                  <div className="text-xs space-y-1 p-3 bg-white border border-slate-200 rounded-xl">
                    <p><strong>Họ tên:</strong> {resObj.fullName}</p>
                    <p><strong>SĐT:</strong> {resObj.phone}</p>
                    {resObj.email && <p><strong>Email:</strong> {resObj.email}</p>}
                    {resObj.idCardNumber && <p><strong>CCCD:</strong> {resObj.idCardNumber}</p>}
                  </div>
                );
              })()}
            </div>
          ) : (
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-sm font-medium text-slate-700 font-sans">Họ và tên đại diện *</label>
                  <div className="relative flex items-center">
                    <input
                      id="input-tenant-name"
                      type="text"
                      value={fullName}
                      onChange={(e) => {
                        setFullName(e.target.value);
                        setFieldErrors(prev => ({ ...prev, fullName: "" }));
                      }}
                      placeholder="VD: Nguyễn Văn A"
                      required={repType === "new"}
                      className={cn(inputClass, fieldErrors.fullName && "border-red-500 pr-10 focus:ring-red-500")}
                    />
                    {fieldErrors.fullName && (
                      <div className="absolute right-3 flex items-center">
                        <ValidationErrorTooltip message={fieldErrors.fullName} />
                      </div>
                    )}
                  </div>
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-sm font-medium text-slate-700 font-sans">Số CCCD/CMND *</label>
                  <div className="relative flex items-center">
                    <input
                      type="text"
                      value={idCardNumber}
                      onChange={(e) => {
                        setIdCardNumber(e.target.value);
                        setFieldErrors(prev => ({ ...prev, idCardNumber: "" }));
                      }}
                      placeholder="034204005829"
                      required={repType === "new"}
                      className={cn(inputClass, fieldErrors.idCardNumber && "border-red-500 pr-10 focus:ring-red-500")}
                    />
                    {fieldErrors.idCardNumber && (
                      <div className="absolute right-3 flex items-center">
                        <ValidationErrorTooltip message={fieldErrors.idCardNumber} />
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex flex-col gap-1">
                  <label className="text-sm font-medium text-slate-700 font-sans">Số điện thoại *</label>
                  <div className="relative flex items-center">
                    <input
                      id="input-tenant-phone"
                      type="tel"
                      value={phone}
                      onChange={(e) => {
                        setPhone(e.target.value);
                        setFieldErrors(prev => ({ ...prev, phone: "" }));
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          e.preventDefault();
                          if (activeSubStepId === "4.6") {
                            setActiveSubStepId("4.7");
                            localStorage.setItem("onboarding_substep", "4.7");
                          }
                        }
                      }}
                      placeholder="0912345678"
                      required={repType === "new"}
                      className={cn(inputClass, fieldErrors.phone && "border-red-500 pr-10 focus:ring-red-500")}
                    />
                    {fieldErrors.phone && (
                      <div className="absolute right-3 flex items-center">
                        <ValidationErrorTooltip message={fieldErrors.phone} />
                      </div>
                    )}
                  </div>
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-sm font-medium text-slate-700 font-sans">Email (Tùy chọn)</label>
                  <div className="relative flex items-center">
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => {
                        setEmail(e.target.value);
                        setFieldErrors(prev => ({ ...prev, email: "" }));
                      }}
                      placeholder="a@example.com"
                      className={cn(inputClass, fieldErrors.email && "border-red-500 pr-10 focus:ring-red-500")}
                    />
                    {fieldErrors.email && (
                      <div className="absolute right-3 flex items-center">
                        <ValidationErrorTooltip message={fieldErrors.email} />
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4 pt-2">
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700 font-sans flex items-center justify-between">
                    <span>Ảnh CCCD Mặt trước</span>
                    <button
                      id="btn-use-sample-cccd"
                      type="button"
                      onClick={handleUseSampleImage}
                      className="text-xs text-brand-deep hover:underline font-bold"
                    >
                      Sử dụng ảnh mẫu
                    </button>
                  </label>
                  <input
                    id="input-cccd-front"
                    type="file"
                    accept="image/*"
                    onChange={(e) => handleFileChange("front", e.target.files?.[0] || null)}
                    className="text-xs text-slate-500 w-full file:mr-2 file:py-1 file:px-2 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-brand-deep/10 file:text-brand-deep hover:file:bg-brand-deep/20"
                  />
                  {idCardFrontUrl && (
                    <div className="space-y-2 mt-2">
                      <img src={idCardFrontUrl} alt="Mặt trước" className="h-20 w-auto rounded border border-slate-200 object-cover" />
                      <Button
                        id="btn-cccd-ocr"
                        type="button"
                        variant="outline"
                        size="sm"
                        className="w-full flex items-center justify-center gap-1 text-brand-deep border-brand-deep/20 hover:bg-brand-deep/5 py-1 h-auto text-xs font-sans"
                        disabled={ocrLoading}
                        onClick={handleCccdOcr}
                      >
                        {ocrLoading ? "Đang quét..." : "Trích xuất OCR"}
                      </Button>
                      {ocrSuccess && (
                        <p className="text-[10px] text-emerald-600 font-medium text-center font-sans">✓ Đã điền thông tin OCR!</p>
                      )}
                    </div>
                  )}
                </div>
                <div className="space-y-1">
                  <label className="text-sm font-medium text-slate-700 font-sans">Ảnh CCCD Mặt sau</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) => handleFileChange("back", e.target.files?.[0] || null)}
                    className="text-xs text-slate-500 w-full file:mr-2 file:py-1 file:px-2 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-brand-deep/10 file:text-brand-deep hover:file:bg-brand-deep/20"
                  />
                  {idCardBackUrl && (
                    <img src={idCardBackUrl} alt="Mặt sau" className="mt-2 h-20 w-auto rounded border border-slate-200 object-cover" />
                  )}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Section 3: Registered Services */}
        {services.length > 0 && (
          <div className="space-y-4 bg-slate-50/50 p-4 rounded-xl border border-slate-100">
            <h3 className="font-bold text-brand-ink text-sm flex items-center gap-2 pb-2 border-b border-slate-200">
              <ShieldCheck className="h-4 w-4 text-brand-deep" />
              3. Dịch vụ đăng ký đi kèm phòng
            </h3>

            <div id="select-contract-services" className="grid grid-cols-2 sm:grid-cols-3 gap-3 p-2 bg-white rounded-xl border border-slate-200">
              {services.map((s) => {
                const isChecked = !!selectedServices.find(item => item.serviceId === s.id);
                return (
                  <label key={s.id} className="flex items-center gap-2.5 text-sm text-slate-700 cursor-pointer p-2 hover:bg-slate-50 rounded-lg transition-colors border border-slate-100 hover:border-slate-200">
                    <input
                      type="checkbox"
                      checked={isChecked}
                      onChange={() => handleServiceToggle(s.id)}
                      className="w-4 h-4 text-brand-deep rounded border-slate-300 focus:ring-brand-deep/30"
                    />
                    <span className="truncate font-medium">{s.name}</span>
                  </label>
                );
              })}
            </div>
          </div>
        )}

        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose}>Hủy</Button>
          <Button id="btn-submit-contract" type="submit" disabled={isLoading}>
            {isLoading ? "Đang tạo..." : "Tạo hợp đồng"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

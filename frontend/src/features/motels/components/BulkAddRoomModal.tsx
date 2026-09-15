import { useState, useMemo, useEffect } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { roomService, type RoomResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { formatVnStyle, stripVnStyle } from "@/lib/utils";
import { useTourGuide } from "@/hooks/useTourGuide";

interface BulkAddRoomModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  motelId: number;
}

interface RoomPreviewItem {
  floor: number;
  roomNumber: string;
  area?: number;
  basePrice: number;
}

export function BulkAddRoomModal({ isOpen, onClose, onSuccess, motelId }: BulkAddRoomModalProps) {
  const { activeSubStepId, setActiveSubStepId } = useTourGuide();
  const [fromFloor, setFromFloor] = useState("1");
  const [toFloor, setToFloor] = useState("1");
  const [roomsPerFloor, setRoomsPerFloor] = useState("5");
  const [area, setArea] = useState("");
  const [basePrice, setBasePrice] = useState("");
  
  const [existingRooms, setExistingRooms] = useState<RoomResult[]>([]);
  const [isCreating, setIsCreating] = useState(false);
  const [progressText, setProgressText] = useState("");
  const [globalError, setGlobalError] = useState("");

  useEffect(() => {
    if (isOpen) {
      setGlobalError("");
      setProgressText("");
      roomService.list(motelId)
        .then(res => setExistingRooms(res.content))
        .catch(err => console.error("Failed to load existing rooms for numbering sequence", err));
    }
  }, [isOpen, motelId]);

  const previewRooms = useMemo(() => {
    const list: RoomPreviewItem[] = [];
    const start = parseInt(fromFloor, 10);
    const end = parseInt(toFloor, 10);
    const count = parseInt(roomsPerFloor, 10);
    const priceVal = parseFloat(basePrice) || 0;
    const areaVal = area ? parseFloat(area) : undefined;

    if (isNaN(start) || isNaN(end) || isNaN(count) || start <= 0 || end < start || count <= 0) {
      return [];
    }

    for (let f = start; f <= end; f++) {
      let startSuffix = 1;
      const floorRooms = existingRooms.filter(room => Number(room.floor) === f);
      if (floorRooms.length > 0) {
        const suffixes = floorRooms.map(room => {
          const numStr = room.roomNumber.replace(/^[a-zA-Z\s]*/, ""); // strip prefix letters
          const floorStr = f.toString();
          if (numStr.startsWith(floorStr)) {
            const suffixStr = numStr.slice(floorStr.length);
            const parsed = parseInt(suffixStr, 10);
            return isNaN(parsed) ? 0 : parsed;
          }
          const parsed = parseInt(numStr, 10);
          return isNaN(parsed) ? 0 : parsed;
        });
        startSuffix = Math.max(...suffixes, 0) + 1;
      }

      for (let r = startSuffix; r < startSuffix + count; r++) {
        const roomNumber = `P${f}${String(r).padStart(2, "0")}`;
        list.push({
          floor: f,
          roomNumber,
          area: areaVal,
          basePrice: priceVal,
        });
      }
    }
    return list;
  }, [fromFloor, toFloor, roomsPerFloor, area, basePrice, existingRooms]);

  const handleBulkCreate = async () => {
    setGlobalError("");
    setIsCreating(true);
    setProgressText("Đang gửi yêu cầu tạo phòng...");
    
    try {
      const roomsData = previewRooms.map(r => ({
        roomNumber: r.roomNumber,
        floor: r.floor,
        area: r.area,
        basePrice: r.basePrice,
      }));
      
      await roomService.createBulk(motelId, { rooms: roomsData });
      
      setProgressText(`Tạo thành công ${previewRooms.length} phòng.`);
      if (onSuccess) {
        onSuccess();
      }
      onClose();
    } catch (err) {
      setGlobalError(extractError(err));
      setProgressText("");
    } finally {
      setIsCreating(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Tạo phòng hàng loạt">
      <div className="space-y-4 max-h-[80vh] overflow-y-auto pr-1">
        {globalError && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
            {globalError}
          </div>
        )}

        <div className="grid grid-cols-3 gap-3">
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-600">Từ tầng *</label>
            <input
              type="number"
              value={fromFloor}
              onChange={(e) => setFromFloor(e.target.value)}
              min={1}
              required
              disabled={isCreating}
              className={inputClass}
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-600">Đến tầng *</label>
            <input
              type="number"
              value={toFloor}
              onChange={(e) => setToFloor(e.target.value)}
              min={1}
              required
              disabled={isCreating}
              className={inputClass}
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-600">Số phòng/tầng *</label>
            <input
              id="input-bulk-quantity"
              type="number"
              value={roomsPerFloor}
              onChange={(e) => setRoomsPerFloor(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  if (activeSubStepId === "2.2") {
                    setActiveSubStepId("2.3");
                    localStorage.setItem("onboarding_substep", "2.3");
                  }
                }
              }}
              min={1}
              required
              disabled={isCreating}
              className={inputClass}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-600">Diện tích mặc định (m²) *</label>
            <input
              id="input-room-area"
              type="number"
              step="0.1"
              value={area}
              onChange={(e) => setArea(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  if (activeSubStepId === "2.4") {
                    setActiveSubStepId("2.5");
                    localStorage.setItem("onboarding_substep", "2.5");
                    handleBulkCreate();
                  }
                }
              }}
              placeholder="VD: 25"
              required
              disabled={isCreating}
              className={inputClass}
            />
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-600">Giá thuê mặc định (đ) *</label>
            <input
              id="input-room-price"
              type="text"
              value={formatVnStyle(basePrice)}
              onChange={(e) => setBasePrice(stripVnStyle(e.target.value))}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  if (activeSubStepId === "2.3") {
                    setActiveSubStepId("2.4");
                    localStorage.setItem("onboarding_substep", "2.4");
                  }
                }
              }}
              placeholder="VD: 3.000.000"
              required
              disabled={isCreating}
              className={inputClass}
            />
          </div>
        </div>

        {/* Progress or Preview section */}
        <div className="space-y-2 mt-4">
          <div className="flex justify-between items-center">
            <h4 className="text-sm font-bold text-slate-700">
              Danh sách phòng sẽ tạo ({previewRooms.length} phòng)
            </h4>
            {progressText && (
              <span className="text-xs font-medium text-brand-deep">{progressText}</span>
            )}
          </div>

          <div className="border border-slate-100 rounded-xl bg-slate-50 p-3 max-h-48 overflow-y-auto space-y-1.5 text-xs text-slate-600">
            {previewRooms.length > 0 ? (
              previewRooms.map((room, idx) => (
                <div key={idx} className="flex justify-between items-center py-1 border-b border-slate-200/50 last:border-0">
                  <span>
                    Phòng <strong>{room.roomNumber}</strong> (Tầng {room.floor}) - {room.area || "?"}m² - {room.basePrice.toLocaleString()}đ
                  </span>
                  <span className="text-slate-400">Sẵn sàng</span>
                </div>
              ))
            ) : (
              <div className="text-center text-slate-400 py-4">Nhập thông tin tầng và số phòng hợp lệ để xem trước</div>
            )}
          </div>
        </div>

        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose} disabled={isCreating}>
            Hủy
          </Button>
          <Button
            id="btn-submit-bulk-rooms"
            onClick={handleBulkCreate}
            disabled={isCreating || previewRooms.length === 0}
          >
            {isCreating ? "Đang xử lý..." : "Tạo hàng loạt"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}

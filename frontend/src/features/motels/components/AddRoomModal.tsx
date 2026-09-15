import { useState, useEffect } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { roomService, type RoomResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { formatVnStyle, stripVnStyle } from "@/lib/utils";

interface AddRoomModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
  motelId: number;
}

export function AddRoomModal({ isOpen, onClose, onSuccess, motelId }: AddRoomModalProps) {
  const [roomNumber, setRoomNumber] = useState("");
  const [floor, setFloor] = useState("1");
  const [area, setArea] = useState("");
  const [basePrice, setBasePrice] = useState("");
  const [description, setDescription] = useState("");
  const [existingRooms, setExistingRooms] = useState<RoomResult[]>([]);
  const [isManuallyEdited, setIsManuallyEdited] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const loadRooms = async () => {
    try {
      const res = await roomService.list(motelId);
      setExistingRooms(res.content || []);
    } catch (err) {
      console.error("Failed to load rooms", err);
    }
  };

  useEffect(() => {
    if (isOpen && motelId) {
      loadRooms();
      setIsManuallyEdited(false);
    }
  }, [isOpen, motelId]);

  useEffect(() => {
    if (!isManuallyEdited && isOpen) {
      const floorNum = parseInt(floor, 10) || 1;
      const count = existingRooms.filter((r) => r.floor === floorNum).length;
      const suggested = `P${floorNum}${String(count + 1).padStart(2, "0")}`;
      setRoomNumber(suggested);
    }
  }, [floor, existingRooms, isManuallyEdited, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);
    try {
      await roomService.create(motelId, {
        roomNumber: roomNumber.trim(),
        floor: parseInt(floor, 10),
        area: area ? parseFloat(area) : undefined,
        basePrice: parseFloat(basePrice),
        description: description.trim() || undefined,
      });
      setRoomNumber("");
      setFloor("1");
      setArea("");
      setBasePrice("");
      setDescription("");
      setIsManuallyEdited(false);
      onSuccess?.();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setIsLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-2.5 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep/30 focus:border-brand-deep transition-all";

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Thêm phòng mới">
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
            {error}
          </div>
        )}

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Tên/Số phòng *</label>
            <input
              type="text"
              value={roomNumber}
              onChange={(e) => {
                setRoomNumber(e.target.value);
                setIsManuallyEdited(true);
              }}
              placeholder="VD: 101, 102"
              required
              className={inputClass}
            />
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Tầng *</label>
            <input
              type="number"
              value={floor}
              onChange={(e) => setFloor(e.target.value)}
              min={1}
              required
              className={inputClass}
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Diện tích (m²)</label>
            <input
              type="number"
              step="0.1"
              value={area}
              onChange={(e) => setArea(e.target.value)}
              placeholder="VD: 25.5"
              className={inputClass}
            />
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Giá thuê (đ/tháng) *</label>
            <input
              type="text"
              value={formatVnStyle(basePrice)}
              onChange={(e) => setBasePrice(stripVnStyle(e.target.value))}
              placeholder="VD: 3.000.000"
              required
              className={inputClass}
            />
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-sm font-medium text-slate-700">Ghi chú</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Thông tin thêm về phòng (tùy chọn)"
            rows={2}
            className={`${inputClass} resize-none`}
          />
        </div>

        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>
            Hủy
          </Button>
          <Button type="submit" disabled={isLoading}>
            {isLoading ? "Đang lưu..." : "Thêm phòng"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

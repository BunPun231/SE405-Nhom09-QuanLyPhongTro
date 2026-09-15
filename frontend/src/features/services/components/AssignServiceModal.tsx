import { useState, useEffect } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { CheckSquare, Square } from "lucide-react";
import { roomService, type RoomResult } from "@/services/motelService";
import { serviceService, type ServiceResult } from "@/services/serviceService";
import { extractError } from "@/lib/api";

interface AssignServiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  motelId: number;
  service: ServiceResult;
}

export function AssignServiceModal({ isOpen, onClose, motelId, service }: AssignServiceModalProps) {
  const [rooms, setRooms] = useState<RoomResult[]>([]);
  const [selectedRoomIds, setSelectedRoomIds] = useState<number[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (isOpen) {
      setLoading(true);
      setError("");
      roomService.list(motelId)
        .then(async (res) => {
          setRooms(res.content);
          try {
            const assignments = await Promise.all(
              res.content.map(async (room) => {
                try {
                  const svcs = await serviceService.listByRoom(motelId, room.hashid);
                  const isAssigned = svcs.some((s) => s.id === service.id);
                  return { roomId: room.id, isAssigned };
                } catch {
                  return { roomId: room.id, isAssigned: false };
                }
              })
            );
            const initiallySelected = assignments
              .filter((a) => a.isAssigned)
              .map((a) => a.roomId);
            setSelectedRoomIds(initiallySelected);
          } catch (err) {
            console.error("Failed to load service assignments", err);
          }
        })
        .catch((err) => setError(extractError(err)))
        .finally(() => setLoading(false));
    }
  }, [isOpen, motelId, service.id]);

  const toggleRoom = (roomId: number) => {
    setSelectedRoomIds((prev) =>
      prev.includes(roomId) ? prev.filter((id) => id !== roomId) : [...prev, roomId]
    );
  };

  const selectAll = () => setSelectedRoomIds(rooms.map((r) => r.id));
  const deselectAll = () => setSelectedRoomIds([]);

  const handleSave = async () => {
    if (selectedRoomIds.length === 0) {
      setError("Vui lòng chọn ít nhất một phòng.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      await serviceService.assignToRooms(motelId, service.id, selectedRoomIds);
      onClose();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Áp dụng dịch vụ: ${service?.name}`}>
      <div className="space-y-4">
        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
            {error}
          </div>
        )}

        <div className="flex justify-between items-center px-1">
          <span className="text-sm font-medium text-slate-700">
            Chọn phòng áp dụng ({selectedRoomIds.length}/{rooms.length})
          </span>
          <div className="flex gap-2 text-sm text-brand-deep">
            <button onClick={selectAll} className="hover:underline">Chọn tất cả</button>
            <span>|</span>
            <button onClick={deselectAll} className="hover:underline">Bỏ chọn</button>
          </div>
        </div>

        {loading ? (
          <div className="flex justify-center p-8">
            <div className="animate-spin rounded-full h-8 w-8 border-2 border-brand-deep border-t-transparent" />
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 max-h-64 overflow-y-auto p-1">
            {rooms.map((room) => {
              const isSelected = selectedRoomIds.includes(room.id);
              return (
                <button
                  key={room.id}
                  onClick={() => toggleRoom(room.id)}
                  className={`flex items-center gap-2 p-3 rounded-xl border text-left transition-all ${
                    isSelected
                      ? "border-brand-deep bg-brand-deep/5 text-brand-ink"
                      : "border-slate-200 hover:border-slate-300 text-slate-600"
                  }`}
                >
                  {isSelected ? (
                    <CheckSquare size={18} className="text-brand-deep flex-shrink-0" />
                  ) : (
                    <Square size={18} className="text-slate-300 flex-shrink-0" />
                  )}
                  <span className="font-medium text-sm truncate">P.{room.roomNumber}</span>
                </button>
              );
            })}
          </div>
        )}

        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button variant="outline" onClick={onClose} disabled={saving}>Hủy</Button>
          <Button onClick={handleSave} disabled={saving || selectedRoomIds.length === 0}>
            {saving ? "Đang lưu..." : "Áp dụng"}
          </Button>
        </div>
      </div>
    </Modal>
  );
}

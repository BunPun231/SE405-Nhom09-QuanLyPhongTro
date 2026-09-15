import { useState } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { RoomResult, roomService } from "@/services/motelService";
import { formatCurrency, formatVnStyle, stripVnStyle } from "@/lib/utils";
import { extractError } from "@/lib/api";

interface RoomDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  room: RoomResult;
  onSuccess?: () => void;
}

export function RoomDetailModal({ isOpen, onClose, room, onSuccess }: RoomDetailModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [status, setStatus] = useState(room.status);
  
  // form state
  const [roomNumber, setRoomNumber] = useState(room.roomNumber);
  const [floor, setFloor] = useState(room.floor.toString());
  const [area, setArea] = useState(room.area?.toString() || "");
  const [basePrice, setBasePrice] = useState(room.basePrice.toString());
  const [description, setDescription] = useState(room.description || "");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleUpdateStatus = async (newStatus: string) => {
    try {
      await roomService.updateStatus(room.motelId, room.hashid, { status: newStatus });
      setStatus(newStatus as any);
      onSuccess?.();
    } catch (err) {
      alert(extractError(err));
      setStatus(room.status);
    }
  };

  const handleSaveInfo = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await roomService.update(room.motelId, room.hashid, {
        roomNumber: roomNumber.trim(),
        floor: parseInt(floor, 10),
        area: area ? parseFloat(area) : undefined,
        basePrice: parseFloat(basePrice),
        description: description.trim() || undefined,
      });
      setIsEditing(false);
      onSuccess?.();
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm(`Xóa phòng ${room.roomNumber}? Thao tác này không thể hoàn tác.`)) return;
    try {
      await roomService.delete(room.motelId, room.hashid);
      onClose();
      onSuccess?.();
    } catch (err) {
      alert(extractError(err));
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Chi tiết phòng - ${room.roomNumber}`} size="lg">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex gap-2 items-center">
            <span className="text-sm text-slate-500">Trạng thái:</span>
            <select 
              className="text-sm font-medium rounded-lg border border-slate-200 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-brand-deep"
              value={status}
              onChange={(e) => handleUpdateStatus(e.target.value)}
              disabled={room.status === 'RENTED'}
            >
              <option value="AVAILABLE">Trống</option>
              <option value="RENTED" disabled>Đang thuê</option>
              <option value="DEPOSITED">Đặt cọc</option>
              <option value="REPAIRING">Sửa chữa</option>
              <option value="OUT_OF_BUSINESS">Ngừng hoạt động</option>
            </select>
          </div>
          <Button variant="outline" size="sm" onClick={() => setIsEditing(!isEditing)}>
            {isEditing ? "Hủy sửa" : "Chỉnh sửa thông tin"}
          </Button>
        </div>

        {error && (
          <div className="rounded-xl bg-red-50 border border-red-100 p-3 text-sm text-red-700">
            {error}
          </div>
        )}

        {isEditing ? (
          <form className="space-y-4" onSubmit={handleSaveInfo}>
            <div className="grid grid-cols-2 gap-4">
              <Input label="Tên/Số phòng" value={roomNumber} onChange={(e) => setRoomNumber(e.target.value)} required />
              <Input label="Tầng" type="number" value={floor} onChange={(e) => setFloor(e.target.value)} required />
              <Input label="Diện tích (m²)" type="number" step="0.1" value={area} onChange={(e) => setArea(e.target.value)} />
              <Input
                label="Giá thuê/tháng"
                type="text"
                value={formatVnStyle(basePrice)}
                onChange={(e) => setBasePrice(stripVnStyle(e.target.value))}
                required
              />
              <Input label="Ghi chú" value={description} onChange={(e) => setDescription(e.target.value)} />
            </div>
            <div className="flex justify-end pt-4">
              <Button type="submit" disabled={loading}>
                {loading ? "Đang lưu..." : "Lưu thay đổi"}
              </Button>
            </div>
          </form>
        ) : (
          <div className="grid grid-cols-2 gap-y-4 text-sm">
            <div>
              <p className="text-slate-500 mb-1">Tầng</p>
              <p className="font-medium text-slate-900">{room.floor}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Diện tích</p>
              <p className="font-medium text-slate-900">{room.area ? `${room.area} m²` : "—"}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Giá thuê</p>
              <p className="font-medium text-brand-deep">{formatCurrency(room.basePrice)}/tháng</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Số người đang ở</p>
              <p className="font-medium text-slate-900">{room.currentResidentsCount} người</p>
            </div>
            {room.description && (
              <div className="col-span-2">
                <p className="text-slate-500 mb-1">Ghi chú</p>
                <p className="font-medium text-slate-900">{room.description}</p>
              </div>
            )}
          </div>
        )}

        <div className="pt-6 border-t border-slate-100">
          <h3 className="font-semibold text-brand-ink mb-4">Khách đang thuê</h3>
          {room.status === "RENTED" && room.currentResidentsCount > 0 ? (
            <div className="bg-slate-50 p-4 rounded-lg flex justify-between items-center border border-slate-200">
              <div>
                <p className="font-medium text-brand-ink">Có khách đang ở</p>
                <p className="text-sm text-slate-500">({room.currentResidentsCount} người)</p>
              </div>
              {/* Navigate to residents page or contract page */}
              <Button variant="outline" size="sm">Xem hợp đồng</Button>
            </div>
          ) : (
            <p className="text-sm text-slate-500 italic">Phòng đang trống</p>
          )}
        </div>
        
        <div className="pt-4 border-t border-slate-100 flex justify-between">
          <Button variant="danger" size="sm" onClick={handleDelete}>Xóa phòng</Button>
          <Button variant="outline" onClick={onClose}>Đóng</Button>
        </div>
      </div>
    </Modal>
  );
}

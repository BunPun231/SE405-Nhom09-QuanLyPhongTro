import { useState, useEffect, useCallback } from "react";
import { Plus, Edit2, Trash2, Building2, AlertCircle, RefreshCw, Layers } from "lucide-react";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { AddMotelModal } from "../components/AddMotelModal";
import { useTourGuide } from "@/hooks/useTourGuide";
import { AddRoomModal } from "../components/AddRoomModal";
import { RoomDetailModal } from "../components/RoomDetailModal";
import { BulkAddRoomModal } from "../components/BulkAddRoomModal";
import { motelService, roomService, type MotelResult, type RoomResult } from "@/services/motelService";
import { extractError } from "@/lib/api";
import { formatCurrency } from "@/lib/utils";

const ROOM_STATUS_LABEL: Record<string, string> = {
  AVAILABLE: "Trống",
  RENTED: "Đang thuê",
  DEPOSITED: "Đặt cọc",
  REPAIRING: "Sửa chữa",
  OUT_OF_BUSINESS: "Ngừng hoạt động",
};

const ROOM_STATUS_COLOR: Record<string, string> = {
  AVAILABLE: "bg-emerald-100 text-emerald-700 border-emerald-200",
  RENTED: "bg-blue-100 text-blue-700 border-blue-200",
  DEPOSITED: "bg-violet-100 text-violet-700 border-violet-200",
  REPAIRING: "bg-amber-100 text-amber-700 border-amber-200",
  OUT_OF_BUSINESS: "bg-slate-100 text-slate-500 border-slate-200",
};

const ROOM_CARD_BORDER: Record<string, string> = {
  AVAILABLE: "hover:border-emerald-400",
  RENTED: "hover:border-blue-400",
  DEPOSITED: "hover:border-violet-400",
  REPAIRING: "hover:border-amber-400",
  OUT_OF_BUSINESS: "opacity-60",
};

export function MotelListPage() {
  const { refreshStatus } = useTourGuide();
  const [motels, setMotels] = useState<MotelResult[]>([]);
  const [selectedMotelId, setSelectedMotelId] = useState<number | null>(null);
  const [rooms, setRooms] = useState<RoomResult[]>([]);
  const [loading, setLoading] = useState(true);
  const [roomsLoading, setRoomsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isMotelModalOpen, setIsMotelModalOpen] = useState(false);
  const [isAddRoomOpen, setIsAddRoomOpen] = useState(false);
  const [isBulkAddRoomOpen, setIsBulkAddRoomOpen] = useState(false);
  const [editingMotel, setEditingMotel] = useState<MotelResult | undefined>();
  const [selectedRoom, setSelectedRoom] = useState<RoomResult | null>(null);

  const fetchMotels = useCallback(async () => {
    setLoading(true);
    try {
      const result = await motelService.list();
      setMotels(result.content);
      if (result.content.length > 0 && !selectedMotelId) {
        setSelectedMotelId(result.content[0].id);
      }
      setError(null);
    } catch (err) {
      setError(extractError(err));
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchRooms = useCallback(async (motelId: number) => {
    setRoomsLoading(true);
    try {
      const result = await roomService.list(motelId);
      setRooms(result.content);
    } catch (err) {
      console.error("Failed to load rooms:", err);
    } finally {
      setRoomsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMotels();
  }, [fetchMotels]);

  useEffect(() => {
    if (selectedMotelId) {
      fetchRooms(selectedMotelId);
    }
  }, [selectedMotelId, fetchRooms]);

  const handleDeleteMotel = async () => {
    if (!activeMotel) return;
    if (!confirm(`Bạn có chắc chắn muốn xóa khu trọ "${activeMotel.name}" không? Toàn bộ phòng và dữ liệu liên quan sẽ bị xóa.`)) return;
    try {
      await motelService.delete(activeMotel.id);
      setSelectedMotelId(null);
      fetchMotels();
    } catch (err) {
      alert(extractError(err));
    }
  };

  const activeMotel = motels.find((m) => m.id === selectedMotelId);
  const floors = Array.from(new Set(rooms.map((r) => r.floor))).sort((a, b) => a - b);

  const roomsByFloor = (floor: number) => rooms.filter((r) => r.floor === floor);

  if (loading) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="flex justify-between">
          <div className="h-8 bg-slate-100 rounded-lg w-56" />
          <div className="h-10 bg-slate-100 rounded-xl w-36" />
        </div>
        <div className="flex gap-2 border-b border-slate-200 pb-2">
          {[1, 2, 3].map((i) => <div key={i} className="h-9 w-28 bg-slate-100 rounded-lg" />)}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4, 5, 6, 7, 8].map((i) => (
            <div key={i} className="h-32 rounded-xl bg-slate-100" />
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px]">
        <AlertCircle size={40} className="text-red-400 mb-3" />
        <p className="text-slate-600 mb-4">{error}</p>
        <Button onClick={fetchMotels}>
          <RefreshCw size={16} className="mr-2" />
          Thử lại
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold font-display text-brand-ink">Khu trọ & Phòng</h1>
          <p className="text-sm text-slate-500 mt-1">{motels.length} khu trọ</p>
        </div>
        <div className="flex gap-2">
          <Button id="btn-add-motel" onClick={() => { setEditingMotel(undefined); setIsMotelModalOpen(true); }} variant="outline">
            <Plus size={16} className="mr-2" />
            Thêm khu trọ
          </Button>
          <Button id="btn-bulk-create-rooms" onClick={() => setIsBulkAddRoomOpen(true)} disabled={!activeMotel} variant="outline">
            <Layers size={16} className="mr-2" />
            Tạo hàng loạt
          </Button>
          <Button onClick={() => setIsAddRoomOpen(true)} disabled={!activeMotel}>
            <Plus size={16} className="mr-2" />
            Thêm phòng
          </Button>
        </div>
      </div>

      {/* Motel Tabs */}
      {motels.length > 0 ? (
        <>
          <div className="flex gap-2 border-b border-slate-200 pb-2 overflow-x-auto scrollbar-none">
            {motels.map((motel) => (
              <button
                key={motel.id}
                onClick={() => setSelectedMotelId(motel.id)}
                className={`px-4 py-2.5 rounded-t-lg font-medium whitespace-nowrap transition-all text-sm flex items-center gap-2 ${
                  selectedMotelId === motel.id
                    ? "bg-brand-deep text-white shadow-sm"
                    : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                <Building2 size={14} />
                {motel.name}
              </button>
            ))}
          </div>

          {/* Motel info bar */}
          {activeMotel && (
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-4 rounded-2xl shadow-sm border border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-brand-ink">{activeMotel.name}</h2>
                <p className="text-sm text-slate-500">{activeMotel.address}</p>
                <p className="text-xs text-slate-400 mt-0.5">
                  <Layers size={12} className="inline mr-1" />
                  {activeMotel.totalFloors} tầng
                  {activeMotel.description && ` • ${activeMotel.description}`}
                </p>
              </div>
              <div className="flex gap-2">
                {/* Room status summary */}
                <div className="flex gap-2 flex-wrap">
                  {Object.entries(
                    rooms.reduce<Record<string, number>>((acc, r) => {
                      acc[r.status] = (acc[r.status] || 0) + 1;
                      return acc;
                    }, {})
                  ).map(([status, count]) => (
                    <span
                      key={status}
                      className={`text-xs px-2.5 py-1 rounded-lg border font-medium ${ROOM_STATUS_COLOR[status] ?? "bg-slate-100 text-slate-500"}`}
                    >
                      {count} {ROOM_STATUS_LABEL[status] ?? status}
                    </span>
                  ))}
                </div>
                <div className="flex gap-2 ml-2">
                  <Button id="btn-edit-motel" variant="outline" size="sm" onClick={() => { setEditingMotel(activeMotel); setIsMotelModalOpen(true); }}>
                    <Edit2 size={14} className="mr-1.5" />
                    Sửa
                  </Button>
                  <Button variant="danger" size="sm" onClick={handleDeleteMotel}>
                    <Trash2 size={14} className="mr-1.5" />
                    Xóa
                  </Button>
                </div>
              </div>
            </div>
          )}

          {/* Room Grid by Floor */}
          {roomsLoading ? (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 animate-pulse">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <div key={i} className="h-32 rounded-xl bg-slate-100" />
              ))}
            </div>
          ) : rooms.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center bg-white rounded-2xl border border-slate-100">
              <Building2 size={40} className="text-slate-300 mb-3" />
              <p className="text-slate-500 font-medium">Chưa có phòng nào</p>
              <p className="text-sm text-slate-400 mt-1 mb-4">Thêm phòng để bắt đầu quản lý</p>
              <Button onClick={() => setIsAddRoomOpen(true)}>
                <Plus size={16} className="mr-2" />
                Thêm phòng đầu tiên
              </Button>
            </div>
          ) : (
            <div className="space-y-6">
              {floors.map((floor) => (
                <div key={floor} className="space-y-3">
                  <div className="flex items-center gap-3">
                    <h3 className="font-semibold text-slate-700">Tầng {floor}</h3>
                    <div className="flex-1 h-px bg-slate-200" />
                    <span className="text-xs text-slate-400">{roomsByFloor(floor).length} phòng</span>
                  </div>
                  <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3">
                    {roomsByFloor(floor).map((room) => (
                      <button
                        key={room.id}
                        onClick={() => setSelectedRoom(room)}
                        className={`cursor-pointer bg-white border border-slate-200 rounded-2xl p-4 text-left transition-all ${
                          ROOM_CARD_BORDER[room.status] ?? "hover:border-brand-deep"
                        } hover:shadow-md`}
                      >
                        <div className="flex justify-between items-start mb-3">
                          <span className="font-bold text-brand-ink text-lg leading-none">
                            {room.roomNumber}
                          </span>
                          <span
                            className={`text-xs px-2 py-0.5 rounded-full border font-medium ${
                              ROOM_STATUS_COLOR[room.status] ?? "bg-slate-100 text-slate-500"
                            }`}
                          >
                            {ROOM_STATUS_LABEL[room.status] ?? room.status}
                          </span>
                        </div>
                        <div className="text-xs text-slate-500 space-y-1">
                          {room.area && <p>{room.area} m²</p>}
                          <p className="font-semibold text-brand-deep text-sm">
                            {formatCurrency(room.basePrice)}
                            <span className="font-normal text-slate-400">/tháng</span>
                          </p>
                          {room.currentResidentsCount > 0 && (
                            <p className="text-slate-500">
                              👥 {room.currentResidentsCount} người
                            </p>
                          )}
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      ) : (
        <div className="flex flex-col items-center justify-center py-24 text-center bg-white rounded-2xl border border-dashed border-slate-300">
          <Building2 size={48} className="text-slate-300 mb-4" />
          <h3 className="text-lg font-semibold text-slate-600 mb-2">Chưa có khu trọ nào</h3>
          <p className="text-sm text-slate-400 mb-6 max-w-sm">
            Tạo khu trọ đầu tiên để bắt đầu quản lý phòng, khách thuê và hóa đơn.
          </p>
          <Button id="btn-add-motel" onClick={() => { setEditingMotel(undefined); setIsMotelModalOpen(true); }}>
            <Plus size={16} className="mr-2" />
            Tạo khu trọ đầu tiên
          </Button>
        </div>
      )}

      {/* Modals */}
      {selectedRoom && activeMotel && (
        <RoomDetailModal
          isOpen={!!selectedRoom}
          room={selectedRoom}
          onClose={() => setSelectedRoom(null)}
          onSuccess={() => {
            setSelectedRoom(null);
            fetchRooms(activeMotel.id);
          }}
        />
      )}

      {activeMotel && (
        <AddRoomModal
          isOpen={isAddRoomOpen}
          onClose={() => setIsAddRoomOpen(false)}
          motelId={activeMotel.id}
          onSuccess={() => {
            setIsAddRoomOpen(false);
            fetchRooms(activeMotel.id);
          }}
        />
      )}

      {activeMotel && (
        <BulkAddRoomModal
          isOpen={isBulkAddRoomOpen}
          onClose={() => setIsBulkAddRoomOpen(false)}
          motelId={activeMotel.id}
          onSuccess={() => {
            fetchRooms(activeMotel.id);
            refreshStatus();
          }}
        />
      )}

      <AddMotelModal
        isOpen={isMotelModalOpen}
        onClose={() => setIsMotelModalOpen(false)}
        motel={editingMotel}
        onSuccess={() => {
          setIsMotelModalOpen(false);
          fetchMotels();
          refreshStatus();
        }}
      />
    </div>
  );
}

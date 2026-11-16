import React, { useState, useEffect } from "react";
import { roomService, RoomResult } from "@/services/motelService";
import { Search, ChevronDown, Check } from "lucide-react";

interface RoomSelectorProps {
  motelId: number | string;
  filterStatus?: string | string[] | null;
  value: number | string | null;
  onChange: (roomId: number) => void;
  disabled?: boolean;
  placeholder?: string;
  className?: string;
}

export function RoomSelector({
  motelId,
  filterStatus = null,
  value,
  onChange,
  disabled = false,
  placeholder = "Chọn phòng...",
  className = "",
}: RoomSelectorProps) {
  const [rooms, setRooms] = useState<RoomResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState("");

  useEffect(() => {
    if (!motelId) return;
    setLoading(true);
    const statuses =
      filterStatus == null
        ? null
        : (Array.isArray(filterStatus) ? filterStatus : [filterStatus]).map((s) =>
            s === "VACANT" ? "EMPTY" : s
          );
    roomService
      .list(Number(motelId), 0, 200)
      .then((res) => {
        let list = res.content || [];
        if (statuses) {
          list = list.filter((r) => statuses.includes(r.status));
        }
        setRooms(list);
      })
      .catch((err) => console.error("Failed to load rooms for selector", err))
      .finally(() => setLoading(false));
  }, [motelId, filterStatus]);

  const selectedRoom = rooms.find((r) => r.id === Number(value) || r.hashid === String(value));

  const filteredRooms = rooms.filter(
    (r) =>
      r.roomNumber.toLowerCase().includes(search.toLowerCase()) ||
      (r.description && r.description.toLowerCase().includes(search.toLowerCase()))
  );

  return (
    <div className={`relative ${className}`}>
      <button
        type="button"
        disabled={disabled || loading}
        onClick={() => setIsOpen(!isOpen)}
        className="w-full flex items-center justify-between px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-sm font-medium text-slate-700 hover:border-slate-300 focus:outline-none focus:ring-2 focus:ring-brand-deep/20 disabled:opacity-50 disabled:bg-slate-50 transition"
      >
        <span className={selectedRoom ? "text-slate-900 font-semibold" : "text-slate-400"}>
          {loading
            ? "Đang tải danh sách..."
            : selectedRoom
            ? `Phòng ${selectedRoom.roomNumber}${selectedRoom.description ? ` - ${selectedRoom.description}` : ""}`
            : placeholder}
        </span>
        <ChevronDown size={16} className="text-slate-400" />
      </button>

      {isOpen && (
        <div className="absolute z-50 mt-1.5 w-full bg-white border border-slate-200 rounded-xl shadow-xl overflow-hidden p-2 space-y-1 animate-in fade-in zoom-in-95 duration-100">
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Tìm theo số phòng..."
              className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-deep/20"
              autoFocus
            />
          </div>

          <div className="max-h-56 overflow-y-auto space-y-0.5">
            {filteredRooms.length === 0 ? (
              <div className="py-3 text-center text-xs text-slate-400">Không tìm thấy phòng phù hợp</div>
            ) : (
              filteredRooms.map((r) => {
                const isSelected = r.id === Number(value) || r.hashid === String(value);
                return (
                  <button
                    key={r.id}
                    type="button"
                    onClick={() => {
                      onChange(r.id);
                      setIsOpen(false);
                      setSearch("");
                    }}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs transition ${
                      isSelected
                        ? "bg-brand-deep/10 text-brand-deep font-bold"
                        : "hover:bg-slate-50 text-slate-700"
                    }`}
                  >
                    <span>
                      Phòng <strong className="font-semibold">{r.roomNumber}</strong>
                      {r.description ? ` (${r.description})` : ""}
                    </span>
                    {isSelected && <Check size={14} className="text-brand-deep" />}
                  </button>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
}
import { useState } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Resident } from "@/types";
import { mockRooms } from "@/data/mock";

interface ResidentDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  resident: Resident;
}

export function ResidentDetailModal({ isOpen, onClose, resident }: ResidentDetailModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const room = mockRooms.find(r => r.id === resident.roomId);

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={isEditing ? "Chỉnh sửa khách thuê" : "Chi tiết khách thuê"} size="lg">
      <div className="space-y-6">
        {isEditing ? (
          <form className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <Input label="Họ và tên" defaultValue={resident.name} />
              <Input label="CCCD/CMND" defaultValue={resident.identityCard} />
              <Input label="Số điện thoại" defaultValue={resident.phone} />
              <Input label="Email" type="email" defaultValue={resident.email} />
            </div>
            <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
              <Button type="button" variant="outline" onClick={() => setIsEditing(false)}>Hủy</Button>
              <Button type="button" onClick={() => setIsEditing(false)}>Lưu thay đổi</Button>
            </div>
          </form>
        ) : (
          <div className="grid grid-cols-2 gap-y-6 text-sm">
            <div>
              <p className="text-slate-500 mb-1">Họ và tên</p>
              <p className="font-semibold text-brand-ink text-base">{resident.name}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">CCCD/CMND</p>
              <p className="font-medium text-slate-900 text-base">{resident.identityCard}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Email</p>
              <p className="font-medium text-slate-900 text-base">{resident.email || "Không có"}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Số điện thoại</p>
              <p className="font-medium text-slate-900 text-base">{resident.phone}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Phòng đang ở</p>
              <p className="font-medium text-slate-900 text-base">{room?.name}</p>
            </div>
            <div>
              <p className="text-slate-500 mb-1">Ngày vào ở</p>
              <p className="font-medium text-slate-900 text-base">{new Date(resident.joinDate).toLocaleDateString('vi-VN')}</p>
            </div>
          </div>
        )}

        {!isEditing && (
          <div className="pt-4 border-t border-slate-100 flex justify-between">
            <Button variant="outline" onClick={onClose}>Đóng</Button>
            <Button variant="primary" onClick={() => setIsEditing(true)}>Chỉnh sửa</Button>
          </div>
        )}
      </div>
    </Modal>
  );
}

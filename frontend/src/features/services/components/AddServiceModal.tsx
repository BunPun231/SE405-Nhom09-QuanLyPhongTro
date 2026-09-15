import { useState } from "react";
import { Modal } from "@/components/ui/Modal";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";

interface AddServiceModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function AddServiceModal({ isOpen, onClose }: AddServiceModalProps) {
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setTimeout(() => {
      setIsLoading(false);
      onClose();
    }, 500);
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Thêm dịch vụ mới">
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input label="Tên dịch vụ" placeholder="VD: Internet" required />
        <Input label="Mô tả" placeholder="VD: Wifi tốc độ cao" />
        <div className="grid grid-cols-2 gap-4">
          <Input label="Đơn giá" type="number" placeholder="150000" required />
          <div className="flex flex-col gap-1.5 w-full">
            <label className="text-sm font-medium text-slate-700">Đơn vị tính</label>
            <select className="h-10 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-deep">
              <option value="tháng">tháng</option>
              <option value="người">người</option>
              <option value="phòng">phòng</option>
              <option value="kWh">kWh</option>
              <option value="khối">khối</option>
              <option value="lần">lần</option>
            </select>
          </div>
        </div>
        
        <div className="pt-4 border-t border-slate-100 flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onClose}>Hủy</Button>
          <Button type="submit" disabled={isLoading}>
            {isLoading ? "Đang lưu..." : "Thêm dịch vụ"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

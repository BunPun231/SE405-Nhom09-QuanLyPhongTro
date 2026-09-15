import { User, Motel, Room, Resident, Service, Contract, Invoice, MeterReading } from "@/types";

export const mockUsers: User[] = [
  { id: "u1", name: "Nguyễn Văn A", email: "admin@smartboarding.com", role: "MANAGER", avatar: "https://i.pravatar.cc/150?u=a042581f4e29026024d", hasCompletedOnboarding: true }
];

export const mockMotels: Motel[] = [
  { id: "m1", name: "Khu trọ Hoàng Hoa Thám", address: "123 Hoàng Hoa Thám, Tân Bình", floors: 3, totalRooms: 15, rentedRooms: 12 },
  { id: "m2", name: "Khu trọ Lý Thường Kiệt", address: "456 Lý Thường Kiệt, Q10", floors: 2, totalRooms: 10, rentedRooms: 5 }
];

export const mockRooms: Room[] = [
  { id: "r1", motelId: "m1", name: "P101", floor: 1, area: 25, price: 3500000, status: "RENTED", maxTenants: 2 },
  { id: "r2", motelId: "m1", name: "P102", floor: 1, area: 20, price: 3000000, status: "AVAILABLE", maxTenants: 2 },
  { id: "r3", motelId: "m1", name: "P201", floor: 2, area: 30, price: 4000000, status: "MAINTENANCE", maxTenants: 3 },
  { id: "r4", motelId: "m2", name: "P101", floor: 1, area: 20, price: 2500000, status: "RENTED", maxTenants: 2 },
];

export const mockResidents: Resident[] = [
  { id: "res1", roomId: "r1", name: "Trần Thị B", email: "tranthib@email.com", phone: "0907654321", identityCard: "079987654321", joinDate: "2026-01-01", status: "ACTIVE" },
  { id: "res2", roomId: "r4", name: "Lê Văn C", email: "levanc@email.com", phone: "0987654321", identityCard: "079123456789", joinDate: "2025-10-01", status: "ACTIVE" }
];

export const mockServices: Service[] = [
  { id: "s1", name: "Điện", description: "Điện sinh hoạt", price: 3500, unit: "kWh", isActive: true, type: "ELECTRICITY" },
  { id: "s2", name: "Nước", description: "Nước sinh hoạt", price: 20000, unit: "khối", isActive: true, type: "WATER" },
  { id: "s3", name: "Internet", description: "Wifi tốc độ cao", price: 100000, unit: "tháng", isActive: true, type: "INTERNET" },
  { id: "s4", name: "Rác & Vệ sinh", description: "Phí thu gom rác", price: 50000, unit: "tháng", isActive: true, type: "TRASH" }
];

export const mockContracts: Contract[] = [
  { id: "c1", roomId: "r1", residentId: "res1", startDate: "2026-01-01", endDate: "2026-12-31", rentPrice: 3500000, depositAmount: 7000000, status: "ACTIVE" },
  { id: "c2", roomId: "r4", residentId: "res2", startDate: "2025-10-01", endDate: "2026-04-01", rentPrice: 2500000, depositAmount: 2500000, status: "EXPIRING_SOON" }
];

export const mockInvoices: Invoice[] = [
  { id: "inv1", roomId: "r1", month: "04/2026", totalAmount: 4250000, status: "PAID", createdAt: "2026-04-01" },
  { id: "inv2", roomId: "r1", month: "05/2026", totalAmount: 4320000, status: "UNPAID", createdAt: "2026-05-01" }
];

export const mockMeterReadings: MeterReading[] = [
  { id: "mr1", roomId: "r1", type: "ELECTRICITY", month: "05/2026", oldIndex: 1100, newIndex: 1250, consumption: 150, status: "RECORDED" },
  { id: "mr2", roomId: "r1", type: "WATER", month: "05/2026", oldIndex: 40, newIndex: 48, consumption: 8, status: "RECORDED" },
  { id: "mr3", roomId: "r4", type: "ELECTRICITY", month: "05/2026", oldIndex: 200, newIndex: 0, consumption: 0, status: "UNRECORDED" }
];

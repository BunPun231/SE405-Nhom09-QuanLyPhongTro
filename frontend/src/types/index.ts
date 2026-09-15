export type ApiResponse<T> = {
  data: T;
  message?: string;
};

export type UserRole = "ADMIN" | "MANAGER" | "TENANT" | "TECHNICIAN";

export interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  role: UserRole;
  avatar?: string;
  hasCompletedOnboarding: boolean;
}

export interface Motel {
  id: string;
  name: string;
  address: string;
  floors: number;
  totalRooms: number;
  rentedRooms: number;
}

export type RoomStatus = "AVAILABLE" | "RENTED" | "MAINTENANCE" | "INACTIVE";

export interface Room {
  id: string;
  motelId: string;
  name: string;
  floor: number;
  area: number;
  price: number;
  status: RoomStatus;
  maxTenants?: number;
}

export interface Resident {
  id: string;
  roomId: string;
  name: string;
  email?: string;
  phone: string;
  identityCard: string;
  joinDate: string;
  status: "ACTIVE" | "MOVED_OUT";
}

export interface Service {
  id: string;
  name: string;
  description: string;
  price: number;
  unit: string;
  isActive: boolean;
  type: "ELECTRICITY" | "WATER" | "INTERNET" | "TRASH" | "OTHER";
}

export interface Contract {
  id: string;
  roomId: string;
  residentId: string;
  startDate: string;
  endDate: string;
  rentPrice: number;
  depositAmount: number;
  status: "ACTIVE" | "EXPIRING_SOON" | "EXPIRED" | "TERMINATED";
}

export interface Invoice {
  id: string;
  roomId: string;
  month: string;
  totalAmount: number;
  status: "PAID" | "UNPAID" | "OVERDUE" | "CANCELLED";
  createdAt: string;
}

export interface MeterReading {
  id: string;
  roomId: string;
  type: "ELECTRICITY" | "WATER";
  month: string;
  oldIndex: number;
  newIndex: number;
  consumption: number;
  status: "UNRECORDED" | "RECORDED";
}

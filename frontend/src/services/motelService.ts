import { api } from "@/lib/api";

// ============ TYPES ============

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface MotelResult {
  id: number;
  tenantId: string;
  name: string;
  address: string;
  totalFloors: number;
  description?: string;
  createdAt: string;
  billingCycleDay?: number;
  depositPercent?: number;
  bankConfig?: string;
}

export interface MotelCreateRequest {
  name: string;
  address: string;
  totalFloors: number;
  description?: string;
  billingCycleDay?: number;
  depositPercent?: number;
  bankConfig?: string;
}

export interface MotelUpdateRequest {
  name?: string;
  address?: string;
  totalFloors?: number;
  description?: string;
  billingCycleDay?: number;
  depositPercent?: number;
  bankConfig?: string;
}

export interface RoomResult {
  id: number;
  hashid: string;
  motelId: number;
  roomNumber: string;
  floor: number;
  area?: number;
  basePrice: number;
  status: "AVAILABLE" | "EMPTY" | "RENTED" | "DEPOSITED" | "REPAIRING" | "OUT_OF_BUSINESS";
  currentResidentsCount: number;
  description?: string;
}

export interface RoomCreateRequest {
  roomNumber: string;
  floor: number;
  area?: number;
  basePrice: number;
  description?: string;
}

export interface RoomUpdateRequest {
  roomNumber?: string;
  floor?: number;
  area?: number;
  basePrice?: number;
  description?: string;
}

export interface RoomStatusUpdateRequest {
  status: string;
  reason?: string;
}

// ============ MOTEL APIs ============

export const motelService = {
  /** UC21: List motels */
  async list(page = 0, size = 20): Promise<PageResponse<MotelResult>> {
    const res = await api.get<ApiResponse<PageResponse<MotelResult>>>("/api/motels", {
      params: { page, size },
    });
    return res.data.data;
  },

  /** UC22: Get motel detail */
  async get(id: number): Promise<MotelResult> {
    const res = await api.get<ApiResponse<MotelResult>>(`/api/motels/${id}`);
    return res.data.data;
  },

  /** UC20: Create motel */
  async create(data: MotelCreateRequest): Promise<MotelResult> {
    const res = await api.post<ApiResponse<MotelResult>>("/api/motels", data);
    return res.data.data;
  },

  /** UC23: Update motel */
  async update(id: number, data: MotelUpdateRequest): Promise<MotelResult> {
    const res = await api.patch<ApiResponse<MotelResult>>(`/api/motels/${id}`, data);
    return res.data.data;
  },

  /** UC25: Delete motel */
  async delete(id: number): Promise<void> {
    await api.delete(`/api/motels/${id}`);
  },

  /** Save payment configuration */
  async savePaymentConfig(id: number, data: { accountNumber: string; bankName: string }): Promise<void> {
    await api.put(`/api/motels/${id}/payment-config`, data);
  },

  /** Generate secure random secret key */
  async generateSecret(): Promise<string> {
    const res = await api.get<ApiResponse<string>>("/api/motels/generate-secret");
    return res.data.data;
  },
};

// ============ ROOM APIs ============

export const roomService = {
  /** UC27: List rooms in a motel */
  async list(motelId: number, page = 0, size = 100): Promise<PageResponse<RoomResult>> {
    const res = await api.get<ApiResponse<PageResponse<RoomResult>>>(
      `/api/motels/${motelId}/rooms`,
      { params: { page, size } }
    );
    return res.data.data;
  },

  /** UC28: Get room detail */
  async get(motelId: number, roomId: number | string): Promise<RoomResult> {
    const res = await api.get<ApiResponse<RoomResult>>(
      `/api/motels/${motelId}/rooms/${roomId}`
    );
    return res.data.data;
  },

  /** UC26: Create room */
  async create(motelId: number, data: RoomCreateRequest): Promise<RoomResult> {
    const res = await api.post<ApiResponse<RoomResult>>(
      `/api/motels/${motelId}/rooms`,
      data
    );
    return res.data.data;
  },

  /** UC26+: Bulk create rooms */
  async createBulk(motelId: number, data: { rooms: RoomCreateRequest[] }): Promise<RoomResult[]> {
    const res = await api.post<ApiResponse<RoomResult[]>>(
      `/api/motels/${motelId}/rooms/bulk`,
      data
    );
    return res.data.data;
  },

  /** UC29: Update room */
  async update(motelId: number, roomId: number | string, data: RoomUpdateRequest): Promise<RoomResult> {
    const res = await api.patch<ApiResponse<RoomResult>>(
      `/api/motels/${motelId}/rooms/${roomId}`,
      data
    );
    return res.data.data;
  },

  /** UC30: Change room status */
  async updateStatus(motelId: number, roomId: number | string, data: RoomStatusUpdateRequest): Promise<RoomResult> {
    const res = await api.patch<ApiResponse<RoomResult>>(
      `/api/motels/${motelId}/rooms/${roomId}/status`,
      data
    );
    return res.data.data;
  },

  /** UC31: Delete room */
  async delete(motelId: number, roomId: number | string): Promise<void> {
    await api.delete(`/api/motels/${motelId}/rooms/${roomId}`);
  },
};

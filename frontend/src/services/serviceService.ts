import { api } from "@/lib/api";
import type { ApiResponse } from "./motelService";

export interface ServiceTierPricing {
  tierStart?: number;
  tierEnd?: number;
  pricePerUnit: number;
}

export interface ServiceResult {
  id: number;
  motelId: number;
  name: string;
  chargeType: "FIXED" | "METERED" | "PER_PERSON" | "PER_INDEX" | "PER_QUANTITY" | "TIERED";
  unit?: string;
  mandatory: boolean;
  basePrice?: number;
  pricingTiers?: ServiceTierPricing[];
}

export interface ServiceCreateRequest {
  name: string;
  chargeType: string;
  unit?: string;
  mandatory?: boolean;
  basePrice?: number;
  pricingTiers?: ServiceTierPricing[];
}

export interface ServiceUpdateRequest {
  name?: string;
  chargeType?: string;
  unit?: string;
  mandatory?: boolean;
  basePrice?: number;
  pricingTiers?: ServiceTierPricing[];
}

export const serviceService = {
  /** UC33: List services */
  async list(motelId: number): Promise<ServiceResult[]> {
    const res = await api.get<ApiResponse<{ content: ServiceResult[] }>>(
      `/api/motels/${motelId}/services`,
      { params: { size: 100 } }
    );
    return res.data.data.content;
  },

  /** UC34: Get service detail */
  async get(motelId: number, serviceId: number): Promise<ServiceResult> {
    const res = await api.get<ApiResponse<ServiceResult>>(
      `/api/motels/${motelId}/services/${serviceId}`
    );
    return res.data.data;
  },

  /** UC32: Create service */
  async create(motelId: number, data: ServiceCreateRequest): Promise<ServiceResult> {
    const res = await api.post<ApiResponse<ServiceResult>>(
      `/api/motels/${motelId}/services`,
      data
    );
    return res.data.data;
  },

  /** UC35: Update service */
  async update(motelId: number, serviceId: number, data: ServiceUpdateRequest): Promise<ServiceResult> {
    const res = await api.patch<ApiResponse<ServiceResult>>(
      `/api/motels/${motelId}/services/${serviceId}`,
      data
    );
    return res.data.data;
  },

  /** UC36: Delete service */
  async delete(motelId: number, serviceId: number): Promise<void> {
    await api.delete(`/api/motels/${motelId}/services/${serviceId}`);
  },

  /** UC37: Assign service to rooms */
  async assignToRooms(motelId: number, serviceId: number, roomIds: number[]): Promise<void> {
    await api.post(`/api/motels/${motelId}/services/${serviceId}/assign-to-rooms`, { roomIds });
  },

  /** UC37+: Get services assigned to a specific room */
  async listByRoom(motelId: number, roomId: number | string): Promise<ServiceResult[]> {
    const res = await api.get<ApiResponse<ServiceResult[]>>(
      `/api/motels/${motelId}/services/by-room/${roomId}`
    );
    return res.data.data;
  },
};

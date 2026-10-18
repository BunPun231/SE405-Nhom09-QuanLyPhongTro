import { api } from "@/lib/api";
import { PageResponse } from "./adminService";

export interface TechnicianResponse {
  userId: string;
  phone: string;
  email?: string;
  fullName: string;
  status: "ACTIVE" | "LOCKED" | "PENDING" | "INACTIVE";
  expertise: string[];
  available: boolean;
  assignedMotelIds: number[];
}

export interface CreateTechnicianRequest {
  phone: string;
  email?: string;
  fullName: string;
  expertise?: string[];
  assignedMotelIds?: number[];
}

export interface LockTechnicianRequest {
  reason?: string;
}

export const technicianService = {
  /** UC56 - Add technician */
  async createTechnician(body: CreateTechnicianRequest): Promise<TechnicianResponse> {
    const res = await api.post<{ data: TechnicianResponse }>("/api/technicians", body);
    return res.data.data;
  },

  /** UC57 - List technicians */
  async getTechnicians(params?: { page?: number; size?: number }): Promise<PageResponse<TechnicianResponse>> {
    const res = await api.get<{ data: PageResponse<TechnicianResponse> }>("/api/technicians", { params });
    return res.data.data;
  },

  /** UC58 - Get technician detail */
  async getTechnician(techId: string): Promise<TechnicianResponse> {
    const res = await api.get<{ data: TechnicianResponse }>(`/api/technicians/${techId}`);
    return res.data.data;
  },

  /** UC60 - Lock technician */
  async lockTechnician(techId: string, reason?: string): Promise<void> {
    await api.post(`/api/technicians/${techId}/lock`, { reason });
  },

  /** UC62 - Reset technician password */
  async resetPassword(techId: string): Promise<void> {
    await api.post(`/api/technicians/${techId}/reset-password`);
  }
};

import { api } from "@/lib/api";
import type { PageResponse, ApiResponse } from "./motelService";

export interface ResidentResult {
  userId: string;
  phone: string;
  email?: string;
  fullName: string;
  status: "ACTIVE" | "INACTIVE";
  idCardNumber?: string;
  idCardFrontUrl?: string;
  idCardBackUrl?: string;
}

export interface ResidentCreateRequest {
  phone: string;
  email?: string;
  fullName: string;
  idCardNumber: string;
  idCardFrontUrl?: string;
  idCardBackUrl?: string;
}

export interface ResidentUpdateRequest {
  email?: string;
  fullName?: string;
  idCardNumber?: string;
  idCardFrontUrl?: string;
  idCardBackUrl?: string;
}

export const residentService = {
  /** UC50: List residents */
  async list(page = 0, size = 20): Promise<PageResponse<ResidentResult>> {
    const res = await api.get<ApiResponse<PageResponse<ResidentResult>>>("/api/residents", {
      params: { page, size },
    });
    return res.data.data;
  },

  /** UC51: Get resident detail */
  async get(residentId: string): Promise<ResidentResult> {
    const res = await api.get<ApiResponse<ResidentResult>>(`/api/residents/${residentId}`);
    return res.data.data;
  },

  /** UC49: Create resident */
  async create(data: ResidentCreateRequest): Promise<ResidentResult> {
    const res = await api.post<ApiResponse<ResidentResult>>("/api/residents", data);
    return res.data.data;
  },

  /** UC53: Update resident profile */
  async update(residentId: string, data: ResidentUpdateRequest): Promise<ResidentResult> {
    const res = await api.patch<ApiResponse<ResidentResult>>(`/api/residents/${residentId}`, data);
    return res.data.data;
  },

  /** UC54: Deactivate resident */
  async deactivate(residentId: string): Promise<void> {
    await api.post(`/api/residents/${residentId}/deactivate`);
  },

  /** OCR CCCD front image */
  async ocrCccd(data: { base64Image: string; mimeType: string }): Promise<{ fullName: string; idCardNumber: string }> {
    const res = await api.post<ApiResponse<any>>(
      "/api/residents/ocr/idcard",
      data
    );
    const result = res.data.data;
    return {
      fullName: result.fullName || "",
      idCardNumber: result.idNumber || result.idCardNumber || "",
    };
  },
};

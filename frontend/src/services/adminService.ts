import { api } from "@/lib/api";
import { UserProfileResponse } from "./userService";

export interface PageResponse<T> {
  content: T[];
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

export interface ManagerResponse {
  id: string;
  fullName: string;
  email: string;
  phone?: string;
  status: "ACTIVE" | "LOCKED" | "PENDING_VERIFICATION";
  tenantId?: string;
  tenantName?: string;
  avatarUrl?: string;
  createdAt: string;
  lockReason?: string;
}

export interface GetManagersParams {
  search?: string;
  status?: string;
  page?: number;
  size?: number;
}

export interface UpdateManagerStatusRequest {
  status: "ACTIVE" | "LOCKED";
  lockReason?: string;
}

export const adminService = {
  /** UC - View Manager List */
  async getManagers(params?: GetManagersParams): Promise<PageResponse<ManagerResponse>> {
    const res = await api.get<{ data: PageResponse<ManagerResponse> }>("/api/v1/admin/managers", { params });
    return res.data.data;
  },

  /** UC - Lock/Unlock Manager Account */
  async updateManagerStatus(id: string, body: UpdateManagerStatusRequest): Promise<UserProfileResponse> {
    const res = await api.patch<{ data: UserProfileResponse }>(`/api/v1/admin/managers/${id}/status`, body);
    return res.data.data;
  }
};

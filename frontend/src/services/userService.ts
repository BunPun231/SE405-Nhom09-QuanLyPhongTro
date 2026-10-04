import { api } from "@/lib/api";

export interface UserProfileResponse {
  id: string;
  fullName: string;
  email: string;
  phone?: string;
  avatarUrl?: string;
  role: string;
  status: string;
  createdAt: string;
}

export interface UpdateProfileRequest {
  fullName: string;
  phone?: string;
  email?: string;
  avatarUrl?: string;
}

export const userService = {
  /** UC - View Profile */
  async getProfile(): Promise<UserProfileResponse> {
    const res = await api.get<{ data: UserProfileResponse }>("/api/v1/users/profile");
    return res.data.data;
  },

  /** UC - Update Profile */
  async updateProfile(data: UpdateProfileRequest): Promise<UserProfileResponse> {
    const res = await api.put<{ data: UserProfileResponse }>("/api/v1/users/profile", data);
    return res.data.data;
  }
};

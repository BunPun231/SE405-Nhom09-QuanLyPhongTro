import axios, { type AxiosError, type InternalAxiosRequestConfig } from "axios";
import { useTenantStore } from "@/store/tenantStore";
import { useAuthStore } from "@/store/authStore";

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8080";
const TENANT_HEADER = import.meta.env.VITE_TENANT_HEADER ?? "X-Tenant-Id";

export const api = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
});

// Request interceptor — attach JWT + Tenant-Id
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const tenantId = useTenantStore.getState().tenantId;
  const token = useAuthStore.getState().accessToken;

  if (tenantId) {
    config.headers[TENANT_HEADER] = tenantId;
  }
  if (token) {
    config.headers["Authorization"] = `Bearer ${token}`;
  }

  return config;
});

// Response interceptor — handle 401 → logout
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    if (error.response?.status === 401) {
      // Token expired or invalid — clear session and redirect to login
      useAuthStore.getState().logout();
    }
    return Promise.reject(error);
  }
);

/** Helper: extract error message from backend response */
export function extractError(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data as { message?: string; error?: string } | undefined;
    return data?.message ?? data?.error ?? error.message ?? "Đã xảy ra lỗi";
  }
  if (error instanceof Error) {
    // Hide raw JS technical errors from the user UI
    if (error.name === 'TypeError' || error.name === 'ReferenceError') {
      console.error("Technical Error:", error);
      return "Đã xảy ra lỗi hệ thống cục bộ. Vui lòng thử lại hoặc tải lại trang.";
    }
    return error.message;
  }
  return "Đã xảy ra lỗi không xác định";
}

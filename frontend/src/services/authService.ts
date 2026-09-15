import { api } from "@/lib/api";

export interface LoginRequest {
  identity: string;
  password: string;
}

export interface RegisterRequest {
  tenantName: string;
  phone: string;
  email?: string;
  fullName: string;
  password: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken?: string;
  tokenType?: string;
  userId: string;
  tenantId?: string;
  role: string;
  fullName: string;
  hasCompletedOnboarding: boolean;
}

export interface OnboardingStatusResult {
  hasCompletedOnboarding: boolean;
  hasMotel: boolean;
  hasSePayConfig: boolean;
  hasRooms: boolean;
  hasActiveContract: boolean;
  hasMeterReadings: boolean;
  hasInvoice: boolean;
  currentStep: number;
}

export interface ChangePasswordRequest {
  oldPassword: string;
  newPassword: string;
  confirmPassword: string;
}

export interface ForgotPasswordRequest {
  identity: string;
}

export interface ResetPasswordRequest {
  identity: string;
  otp: string;
  newPassword: string;
  confirmPassword: string;
}

export const authService = {
  /** UC02: Login */
  async login(data: LoginRequest): Promise<AuthResponse> {
    const res = await api.post<{ data: AuthResponse }>("/api/public/auth/login", data);
    return res.data.data;
  },

  /** UC01: Register (Manager SaaS) */
  async register(data: RegisterRequest): Promise<void> {
    await api.post("/api/public/auth/register", data);
  },

  /** UC05: Change password */
  async changePassword(data: ChangePasswordRequest): Promise<void> {
    await api.post("/api/v1/auth/change-password", data);
  },

  /** UC06: Forgot password — request reset email */
  async forgotPassword(data: ForgotPasswordRequest): Promise<void> {
    await api.post("/api/v1/auth/forgot-password", data);
  },

  /** UC06: Reset password with token */
  async resetPassword(data: ResetPasswordRequest): Promise<void> {
    await api.post("/api/v1/auth/reset-password", data);
  },

  /** Refresh token */
  async refresh(refreshToken: string): Promise<AuthResponse> {
    const res = await api.post<{ data: AuthResponse }>("/api/public/auth/refresh", { refreshToken });
    return res.data.data;
  },

  /** Get onboarding status */
  async getOnboardingStatus(): Promise<OnboardingStatusResult> {
    const res = await api.get<{ data: OnboardingStatusResult }>("/api/v1/users/onboarding-status");
    return res.data.data;
  },

  /** Mark onboarding as completed */
  async completeOnboarding(): Promise<void> {
    await api.put("/api/v1/users/onboarding-complete");
  }
};

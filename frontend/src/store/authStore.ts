import { create } from "zustand";
import { User } from "@/types";
import { useTenantStore } from "@/store/tenantStore";

type AuthState = {
  accessToken: string | null;
  user: User | null;
  setAccessToken: (token: string | null) => void;
  setUser: (user: User | null) => void;
  login: (token: string, user: User) => void;
  logout: () => void;
};

export const useAuthStore = create<AuthState>((set) => ({
  accessToken: localStorage.getItem("access_token") || null,
  user: JSON.parse(localStorage.getItem("user") || "null"),
  setAccessToken: (token) => {
    if (token) localStorage.setItem("access_token", token);
    else localStorage.removeItem("access_token");
    set({ accessToken: token });
  },
  setUser: (user) => {
    if (user) localStorage.setItem("user", JSON.stringify(user));
    else localStorage.removeItem("user");
    set({ user });
  },
  login: (token, user) => {
    localStorage.setItem("access_token", token);
    localStorage.setItem("user", JSON.stringify(user));
    set({ accessToken: token, user });
  },
  logout: () => {
    localStorage.removeItem("access_token");
    localStorage.removeItem("user");
    useTenantStore.getState().setTenantId(null);
    set({ accessToken: null, user: null });
    // Secure Session Requirement: trigger full page reload to clear cache
    window.location.href = "/login";
  }
}));

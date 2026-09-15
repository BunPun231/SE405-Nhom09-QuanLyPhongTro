import { create } from "zustand";

type TenantState = {
  tenantId: string | null;
  setTenantId: (tenantId: string | null) => void;
};

const TENANT_STORAGE_KEY = "tenant_id";

export const useTenantStore = create<TenantState>((set) => ({
  tenantId: localStorage.getItem(TENANT_STORAGE_KEY),
  setTenantId: (tenantId) => {
    if (tenantId) localStorage.setItem(TENANT_STORAGE_KEY, tenantId);
    else localStorage.removeItem(TENANT_STORAGE_KEY);
    set({ tenantId });
  }
}));

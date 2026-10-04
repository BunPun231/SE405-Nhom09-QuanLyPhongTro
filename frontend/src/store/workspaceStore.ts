import { create } from "zustand";
import { workspaceService, WorkspaceConfig } from "@/services/workspaceService";

type WorkspaceState = {
  modules: Record<string, boolean>;
  isLoading: boolean;
  fetchConfig: () => Promise<void>;
  updateModules: (modules: Record<string, boolean>) => Promise<void>;
};

export const useWorkspaceStore = create<WorkspaceState>((set, get) => ({
  modules: {
    motels: true,
    services: true,
    residents: true,
    contracts: true,
    meter: true,
    invoices: true,
    reports: true,
    auditLog: true
  },
  isLoading: false,

  fetchConfig: async () => {
    try {
      set({ isLoading: true });
      const config = await workspaceService.getConfig();
      if (config && config.modules) {
        set({ modules: { ...get().modules, ...config.modules } });
      }
    } catch {
      // Ignore if fetch fails (fallback to default true)
    } finally {
      set({ isLoading: false });
    }
  },

  updateModules: async (newModules: Record<string, boolean>) => {
    const updated = { ...get().modules, ...newModules };
    set({ modules: updated });
    await workspaceService.updateConfig({ modules: updated });
  }
}));

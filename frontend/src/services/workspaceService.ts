import { api } from "@/lib/api";

export interface WorkspaceConfig {
  modules: Record<string, boolean>;
}

export const workspaceService = {
  /** UC17: Get workspace config */
  async getConfig(): Promise<WorkspaceConfig> {
    const res = await api.get<{ data: WorkspaceConfig }>("/api/v1/workspace/config");
    return res.data.data;
  },

  /** UC17: Update workspace config */
  async updateConfig(config: WorkspaceConfig): Promise<WorkspaceConfig> {
    const res = await api.put<{ data: WorkspaceConfig }>("/api/v1/workspace/config", config);
    return res.data.data;
  }
};

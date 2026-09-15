import { useTenantStore } from "@/store/tenantStore";

export function useTenant() {
  const tenantId = useTenantStore((state) => state.tenantId);
  const setTenantId = useTenantStore((state) => state.setTenantId);

  return { tenantId, setTenantId };
}

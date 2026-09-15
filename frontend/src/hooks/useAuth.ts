import { useAuthStore } from "@/store/authStore";

export function useAuth() {
  const accessToken = useAuthStore((state) => state.accessToken);
  const setAccessToken = useAuthStore((state) => state.setAccessToken);

  return { accessToken, setAccessToken };
}

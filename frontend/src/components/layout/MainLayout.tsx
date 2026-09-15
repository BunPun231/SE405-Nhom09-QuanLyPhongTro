import { Outlet, Navigate } from "react-router-dom";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";
import { useAuthStore } from "@/store/authStore";
import { useWebSocket } from "@/hooks/useWebSocket";
import { TourGuideProvider } from "@/hooks/useTourGuide";
import { TourGuideWidget } from "./TourGuideWidget";

export function MainLayout() {
  const { accessToken } = useAuthStore();
  
  // Connect WebSocket to listen to real-time events
  useWebSocket();

  // Protect route
  if (!accessToken) {
    return <Navigate to="/login" replace />;
  }

  return (
    <TourGuideProvider>
      <div className="flex h-screen bg-white">
        <Sidebar />
        <div className="flex flex-1 flex-col overflow-hidden">
          <Header />
          <main className="flex-1 overflow-y-auto bg-brand-sand/30 p-6 text-brand-ink">
            <Outlet />
          </main>
        </div>
        <TourGuideWidget />
      </div>
    </TourGuideProvider>
  );
}

import { useEffect, useRef } from "react";
import SockJS from "sockjs-client";
import { Client } from "@stomp/stompjs";
import { useAuthStore } from "@/store/authStore";
import { useNotificationStore } from "@/store/notificationStore";

export function useWebSocket() {
  const { accessToken, user } = useAuthStore();
  const addNotification = useNotificationStore((state) => state.addNotification);
  const fetchUnreadCount = useNotificationStore((state) => state.fetchUnreadCount);
  const clientRef = useRef<Client | null>(null);

  useEffect(() => {
    if (!accessToken || !user?.id) {
      return;
    }

    // Connect using VITE_API_BASE_URL (defaults to http://localhost:8080) to reach backend port
    const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8080";
    const socketUrl = apiBaseUrl.startsWith("http") ? `${apiBaseUrl}/ws` : `${window.location.origin}${apiBaseUrl}/ws`;


    const client = new Client({
      webSocketFactory: () => new SockJS(socketUrl),
      connectHeaders: {
        Authorization: `Bearer ${accessToken}`,
      },
      debug: (str) => {
        console.debug("STOMP Debug: " + str);
      },
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
    });

    client.onConnect = () => {
      console.log("Successfully connected to STOMP WebSocket broker");

      // Subscribe to point-to-point notifications channel
      client.subscribe(`/queue/notifications-${user.id}`, (message) => {
        try {
          const payload = JSON.parse(message.body);
          console.log("WebSocket Notification received:", payload);
          addNotification(payload);
        } catch (err) {
          console.error("Error parsing STOMP notification payload:", err);
        }
      });

      // Synchronize unread counts
      fetchUnreadCount();
    };

    client.onStompError = (frame) => {
      console.error("STOMP Broker protocol error:", frame.headers["message"]);
    };

    client.activate();
    clientRef.current = client;

    return () => {
      if (clientRef.current) {
        clientRef.current.deactivate();
        console.log("STOMP client deactivated.");
      }
    };
  }, [accessToken, user?.id, addNotification, fetchUnreadCount]);

  return clientRef.current;
}

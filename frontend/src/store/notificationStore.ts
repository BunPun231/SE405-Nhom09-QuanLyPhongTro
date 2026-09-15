import { create } from "zustand";
import { api } from "@/lib/api";

export interface NotificationResult {
  id: number;
  tenantId?: string;
  recipientUserId: string;
  title: string;
  content: string;
  type: string;
  isRead: boolean;
  actionUrl?: string;
  createdAt: string;
  readAt?: string;
}

type NotificationState = {
  notifications: NotificationResult[];
  unreadCount: number;
  loading: boolean;
  fetchNotifications: () => Promise<void>;
  fetchUnreadCount: () => Promise<void>;
  addNotification: (notification: NotificationResult) => void;
  markAllAsRead: () => Promise<void>;
  markAsRead: (id: number) => Promise<void>;
};

export const useNotificationStore = create<NotificationState>((set, get) => ({
  notifications: [],
  unreadCount: 0,
  loading: false,

  fetchNotifications: async () => {
    set({ loading: true });
    try {
      const res = await api.get<{ content: NotificationResult[] }>("/api/v1/notifications", {
        params: { page: 0, size: 50 },
      });
      set({ notifications: res.data.content || [] });
    } catch (err) {
      console.error("Failed to fetch notifications", err);
    } finally {
      set({ loading: false });
    }
  },

  fetchUnreadCount: async () => {
    try {
      const res = await api.get<number>("/api/v1/notifications/unread-count");
      set({ unreadCount: res.data });
    } catch (err) {
      console.error("Failed to fetch unread count", err);
    }
  },

  addNotification: (notification) => {
    const { notifications, unreadCount } = get();
    if (notifications.some((n) => n.id === notification.id)) return;

    set({
      notifications: [notification, ...notifications],
      unreadCount: notification.isRead ? unreadCount : unreadCount + 1,
    });
  },

  markAllAsRead: async () => {
    try {
      await api.put("/api/v1/notifications/read-all");
      const updated = get().notifications.map((n) => ({ ...n, isRead: true }));
      set({ notifications: updated, unreadCount: 0 });
    } catch (err) {
      console.error("Failed to mark all as read", err);
    }
  },

  markAsRead: async (id) => {
    try {
      await api.put(`/api/v1/notifications/${id}/read`);
      const { notifications, unreadCount } = get();
      const updated = notifications.map((n) => {
        if (n.id === id) {
          return { ...n, isRead: true };
        }
        return n;
      });
      const wasUnread = notifications.find((n) => n.id === id)?.isRead === false;
      set({
        notifications: updated,
        unreadCount: wasUnread ? Math.max(0, unreadCount - 1) : unreadCount,
      });
    } catch (err) {
      console.error(`Failed to mark notification ${id} as read`, err);
    }
  },
}));
